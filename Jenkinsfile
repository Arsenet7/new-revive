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
                    // Using tmpfs instead of volume mount to avoid permission issues
                    args '--user root  '
                }
            }
            steps {
                script {
                    // Create directory for Go cache with the right permissions
                    
                    
                    // Debug: List all directories and files to understand repository structure
                    sh 'ls -la'
                    
                    // Now switch to the regular user for the build process
                    
                    // Navigate to the catalog directory
                    dir("new-revive-catalog/catalog") {
                        // Display go.mod content
                        
                        
                        // Try to build without switching user first
                        sh '''
                            # Build the Go code
                            go build -v .
                            
                            # Check if there are test files and run tests if found
                            if ls *_test.go 1> /dev/null 2>&1; then
                                go test -v .
                            else
                                echo "No test files found, skipping tests"
                            fi
                        '''
                    }
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