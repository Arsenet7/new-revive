pipeline {
    agent {
        label 'new-revive-agent'
    }
    environment {
                SCANNER_HOME = tool 'sonar' // Define the SonarQube scanner tool
            
                SONAR_SCANNER_VERSION = '5.0.1.3006'
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
                                    -Dsonar.login=${SONAR_TOKEN} \
                                    -Dsonar.host.url=${SONAR_URL}
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
    }
    
    post {
        success {
            echo 'Build, tests, and SonarQube analysis completed successfully!'
        }
        failure {
            echo 'Build, tests, or SonarQube analysis failed!'
        }
        always {
            cleanWs()
        }
    }
}
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
    
    
    post {
        success {
            echo 'Build and tests completed successfully!'
        }
        failure {
            echo 'Build or tests failed!'
        }
        always {
            cleanWs()
        }
    }
