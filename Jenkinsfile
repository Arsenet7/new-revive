pipeline {
    agent {
        label 'new-revive-agent'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 2, unit: 'HOURS')
        timestamps()
    }
    
    environment {
        SONAR_PROJECT_KEY = 'new-revive-ui'
        SONAR_PROJECT_NAME = 'New Revive UI'
        SCANNER_HOME = tool 'sonar' // Define the SonarQube scanner tool
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
                                    -Dsonar.tests=src/test/java \
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
        
        stage('Quality Gate') {
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        def qg = waitForQualityGate()
                        if (qg.status == 'OK') {
                            echo "Quality Gate passed with status: ${qg.status}"
                        } else {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }
        
        stage('Package') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-17'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    cd new-revive-ui/ui
                    mvn package -DskipTests
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'new-revive-ui/ui/target/*.jar', fingerprint: true
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline executed successfully!'
            script {
                def sonarUrl = "http://18.224.30.72:9000/dashboard?id=${SONAR_PROJECT_KEY}"
                echo "SonarQube Dashboard: ${sonarUrl}"
                // slackSend(color: 'good', message: "✅ Build Successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER}")
            }
        }
        failure {
            echo 'Pipeline execution failed!'
        }
        unstable {
            echo 'Pipeline execution completed with warnings!'
        }
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}
