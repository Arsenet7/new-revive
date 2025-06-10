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
        DOCKER_REPO = 'arsenet10/revive-ui'
        DOCKER_IMAGE = "${DOCKER_REPO}:${IMAGE_TAG}"
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

        stage('Package Application') {
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
                always {
                    archiveArtifacts artifacts: 'new-revive-ui/ui/target/*.jar', allowEmptyArchive: true
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    // Build Docker image
                    sh '''
                        cd new-revive-ui/ui
                        echo "Building Docker image: ${DOCKER_IMAGE}"
                        
                        
                        # Build the Docker image
                        docker build -t ${DOCKER_IMAGE} .
                        docker tag ${DOCKER_IMAGE} ${DOCKER_REPO}:latest
                    '''
                    
                    // Push to Docker Hub
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-ars-id', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh '''
                            echo "Logging into Docker Hub..."
                            echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin
                            
                            echo "Pushing Docker image: ${DOCKER_IMAGE}"
                            docker push ${DOCKER_IMAGE}
                            docker push ${DOCKER_REPO}:latest
                            
                            echo "Successfully pushed Docker image!"
                        '''
                    }
                }
            }
            post {
                always {
                    // Clean up local images to save space
                    sh '''
                        docker rmi ${DOCKER_IMAGE} || true
                        docker rmi ${DOCKER_REPO}:latest || true
                        docker system prune -f || true
                    '''
                }
                success {
                    echo "Docker image built and pushed successfully: ${DOCKER_IMAGE}"
                }
                failure {
                    echo "Failed to build or push Docker image"
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
                            credentialsId: 'github-token-id',
                            url: 'https://github.com/Arsenet7/new-revive.git'
                        ]]
                    ])

                    dir('helm-repo') {
                        sh '''
                            git config user.name "Jenkins CI"
                            git config user.email "jenkins@company.com"
                            
                            # Create and switch to main branch to avoid detached HEAD
                            git checkout -B main origin/main
                        '''

                        sh """
                            # Update image tag in values.yaml
                            sed -i 's/tag: .*/tag: "${IMAGE_TAG}"/' ${HELM_CHART_PATH}/values.yaml
                            
                            # Update image repository if needed
                            sed -i 's|repository: .*|repository: "${DOCKER_REPO}"|' ${HELM_CHART_PATH}/values.yaml
                        """

                        script {
                            // Use GitHub token for authentication
                            withCredentials([usernamePassword(credentialsId: 'github-token-id', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_TOKEN')]) {
                                sh """
                                    # Configure Git to use the token for authentication
                                    git remote set-url origin https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/Arsenet7/new-revive.git
                                    
                                    git add ${HELM_CHART_PATH}/values.yaml
                                    
                                    # Check if there are changes to commit
                                    if git diff --staged --quiet; then
                                        echo "No changes to commit - image tag is already up to date"
                                    else
                                        git commit -m "Update UI image to ${DOCKER_IMAGE} - Build ${BUILD_NUMBER}"
                                        echo "Pushing changes to repository..."
                                        git push origin main
                                        echo "Successfully updated Helm chart with image ${DOCKER_IMAGE}"
                                    fi
                                """
                                
                            }
                        }
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
            echo 'Build, tests, SonarQube analysis, Docker build/push, and Helm chart update completed successfully!'
            echo "Docker image: ${DOCKER_IMAGE}"
        }
        failure {
            echo 'Pipeline failed! Check the logs for details.'
        }
        always {
            cleanWs()
        }
    }
}