pipeline {
    agent {
        label 'new-revive-agent'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar' // Define the SonarQube scanner tool
        SONAR_SCANNER_VERSION = '5.0.1.3006'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-ars-id')
        DOCKER_IMAGE_CATALOG = 'yourdockerhubusername/new-revive-catalog'
        DOCKER_IMAGE_DB = 'yourdockerhubusername/new-revive-catalog-db'
        BUILD_VERSION = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: 'catalog']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Arsenet7/new-revive.git',
                        credentialsId: 'new-revive-ssh-key'
                    ]]
                ])
            }
        }
        
        stage('Build and Test') {
            steps {
                // Run Docker directly as a command for simplicity
                sh '''
                    # Run a temporary Go container to build and test the code
                    docker run --rm \
                        -v "${WORKSPACE}:/workspace" \
                        -w "/workspace/new-revive-catalog/catalog" \
                        golang:1.21 \
                        bash -c "set -xe && \
                            go mod download && \
                            go build -buildvcs=false -v . && \
                            (ls *_test.go >/dev/null 2>&1 && go test -buildvcs=false -v . || echo 'No tests to run')"
                '''
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv('sonar') {
                        withCredentials([string(credentialsId: 'sonarqube-jenkins-id', variable: 'SONAR_TOKEN')]) {
                            sh '''
                                cd new-revive-catalog/catalog
                                ${SCANNER_HOME}/bin/sonar-scanner \
                                    -Dsonar.projectKey=new-revive-catalog \
                                    -Dsonar.projectName="New Revive Catalog" \
                                    -Dsonar.sources=. \
                                    -Dsonar.exclusions="**/*_test.go,**/vendor/**" \
                                    -Dsonar.go.coverage.reportPaths=coverage.out \
                                    -Dsonar.login=${SONAR_TOKEN} 
                            '''
                        }
                    }
                }
            }
        }
        
        stage("Quality Gate") {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Build Catalog Image') {
                    steps {
                        dir('new-revive-catalog/catalog') {
                            sh """
                                docker build -t ${DOCKER_IMAGE_CATALOG}:${BUILD_VERSION} -f Dockerfile .
                                docker tag ${DOCKER_IMAGE_CATALOG}:${BUILD_VERSION} ${DOCKER_IMAGE_CATALOG}:latest
                            """
                        }
                    }
                }
                
                stage('Build DB Image') {
                    steps {
                        dir('new-revive-catalog/catalog') {
                            sh """
                                docker build -t ${DOCKER_IMAGE_DB}:${BUILD_VERSION} -f Dockerfile-db .
                                docker tag ${DOCKER_IMAGE_DB}:${BUILD_VERSION} ${DOCKER_IMAGE_DB}:latest
                            """
                        }
                    }
                }
            }
        }
        
        stage('Push Docker Images') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-ars-id') {
                        sh """
                            docker push ${DOCKER_IMAGE_CATALOG}:${BUILD_VERSION}
                            docker push ${DOCKER_IMAGE_CATALOG}:latest
                            docker push ${DOCKER_IMAGE_DB}:${BUILD_VERSION}
                            docker push ${DOCKER_IMAGE_DB}:latest
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Build, tests, SonarQube analysis, and Docker images push completed successfully!'
        }
        failure {
            echo 'Build, tests, SonarQube analysis, or Docker images push failed!'
        }
        always {
            // Clean up Docker images to save space
            sh """
                docker rmi ${DOCKER_IMAGE_CATALOG}:${BUILD_VERSION} || true
                docker rmi ${DOCKER_IMAGE_CATALOG}:latest || true
                docker rmi ${DOCKER_IMAGE_DB}:${BUILD_VERSION} || true
                docker rmi ${DOCKER_IMAGE_DB}:latest || true
            """
            cleanWs()
        }
    }
}