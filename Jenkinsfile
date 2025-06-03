pipeline {
    agent {
        label 'new-revive-agent'
    }

    parameters {
        booleanParam(name: 'SKIP_SONAR', defaultValue: false, description: 'Skip SonarQube analysis and quality gate check')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 2, unit: 'HOURS')
        timestamps()
    }

    environment {
        SONAR_PROJECT_KEY = 'new-revive-ui'
        SONAR_PROJECT_NAME = 'New Revive UI'
        SCANNER_HOME = tool 'sonar'
        IMAGE_TAG = "${BUILD_NUMBER}"
        HELM_CHART_PATH = 'helm-revive/ui'
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: 'ui']], 
                    doGenerateSubmoduleConfigurations: false, 
                    extensions: [], 
                    submoduleCfg: [], 
                    userRemoteConfigs: [[
                        credentialsId: 'new-revive-ssh-key',
                        url: 'https://github.com/Arsenet7/new-revive.git'
                    ]]
                ])
            }
        }

        stage('Build with Maven') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-17'
                    reuseNode true
                }
            }
            steps {
                sh 'mvn --version'
                sh '''
                    cd new-revive-ui/ui
                    mvn clean compile
                '''
            }
        }

        stage('Test with Coverage') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-17'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    cd new-revive-ui/ui
                    mvn test 
                '''
            }
            post {
                always {
                    junit 'new-revive-ui/ui/target/surefire-reports/**/*.xml'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'new-revive-ui/ui/target/site/jacoco',
                        reportFiles: 'index.html',
                        reportName: 'JaCoCo Coverage Report'
                    ])
                }
            }
        }

        stage('Static Code Analysis') {
            parallel {
                stage('Checkstyle') {
                    agent {
                        docker {
                            image 'maven:3.8-openjdk-17'
                            reuseNode true
                        }
                    }
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            sh '''
                                cd new-revive-ui/ui
                                mvn checkstyle:check || true
                            '''
                        }
                    }
                }
                stage('PMD') {
                    agent {
                        docker {
                            image 'maven:3.8-openjdk-17'
                            reuseNode true
                        }
                    }
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            sh '''
                                cd new-revive-ui/ui
                                mvn pmd:pmd || true
                            '''
                        }
                    }
                }
                stage('SpotBugs') {
                    agent {
                        docker {
                            image 'maven:3.8-openjdk-17'
                            reuseNode true
                        }
                    }
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            sh '''
                                cd new-revive-ui/ui
                                mvn spotbugs:check || true
                            '''
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression { return !params.SKIP_SONAR }
            }
            steps {
                script {
                    withSonarQubeEnv('sonar') {
                        withCredentials([string(credentialsId: 'sonarqube-jenkins-id', variable: 'SONAR_TOKEN')]) {
                            sh '''
                                cd new-revive-ui/ui
                                ${SCANNER_HOME}/bin/sonar-scanner \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                    -Dsonar.projectName="${SONAR_PROJECT_NAME}" \
                                    -Dsonar.projectVersion=${BUILD_NUMBER} \
                                    -Dsonar.sources=src/main/java \
                                    -Dsonar.java.binaries=target/classes \
                                    -Dsonar.java.test.binaries=target/test-classes \
                                    -Dsonar.junit.reportPaths=target/surefire-reports \
                                    -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                                    -Dsonar.language=java \
                                    -Dsonar.java.coveragePlugin=jacoco \
                                    -Dsonar.exclusions=**/*Test.java,**/*Config.java,**/model/**,**/entity/** \
                                    -Dsonar.test.inclusions=**/*Test.java \
                                    -Dsonar.dynamicAnalysis=reuseReports \
                                    -Dsonar.checkstyle.reportPaths=target/checkstyle-result.xml \
                                    -Dsonar.pmd.reportPaths=target/pmd.xml \
                                    -Dsonar.findbugs.reportPaths=target/spotbugsXml.xml \
                                    -Dsonar.login=${SONAR_TOKEN}
                            '''
                        }
                    }
                }
            }
        }

        stage("Quality Gate") {
            when {
                expression { return !params.SKIP_SONAR }
            }
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Update Helm Chart') {
            steps {
                script {
                    checkout([
                        $class: 'GitSCM', 
                        branches: [[name: 'main']], 
                        doGenerateSubmoduleConfigurations: false, 
                        extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'helm-repo']], 
                        submoduleCfg: [], 
                        userRemoteConfigs: [[
                            credentialsId: 'new-revive-ssh-key',
                            url: 'https://github.com/Arsenet7/new-revive.git'
                        ]]
                    ])

                    dir('helm-repo') {
                        sh '''
                            git config user.name "Jenkins CI"
                            git config user.email "jenkins@company.com"
                            
                            # Create and switch to main branch to avoid detached HEAD
                            git checkout -b main origin/main
                        '''

                        sh """
                            sed -i 's/tag: .*/tag: "${IMAGE_TAG}"/' ${HELM_CHART_PATH}/values.yaml
                        """

                        sh """
                            git add ${HELM_CHART_PATH}/values.yaml
                            git commit -m "Update image tag to ${IMAGE_TAG} - Build ${BUILD_NUMBER}"
                            echo "Pushing changes to repository..."
                            git push 
                            echo "Successfully updated Helm chart with image tag ${IMAGE_TAG}"
                            
                        """
                    }
                }
            }
            post {
                failure {
                    echo "Failed to update Helm chart. Please check Git credentials and repository permissions."
                }
            }
        }
    }

    post {
        success {
            echo 'Build, tests, SonarQube analysis, and Helm chart update completed successfully!'
        }
        failure {
            echo 'Build, tests, SonarQube analysis, or Helm chart update failed!'
        }
        always {
            cleanWs()
        }
    }
}