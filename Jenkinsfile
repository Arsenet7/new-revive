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
            agent {
                docker {
                    image 'golang:1.21'
                    reuseNode true
                }
            }
            steps {
                // Set working directory within the Docker container
                sh 'mkdir -p $GOPATH/src/github.com/Arsenet7/new-revive-catalog'
                sh 'cp -r . $GOPATH/src/github.com/Arsenet7/new-revive-catalog'
                
                // Navigate to the specific catalog directory
                dir('$GOPATH/src/github.com/Arsenet7/new-revive-catalog/catalog') {
                    // Get dependencies
                    sh 'go mod download'
                    
                    // Build specifically the catalog code
                    sh 'go build -v .'
                    
                    // Test specifically the catalog code
                    sh 'go test -v .'
                }
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