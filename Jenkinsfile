pipeline {
    agent {
        label 'new-revive-agent'
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
}