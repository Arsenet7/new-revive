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
                    args '-u root'
                    args '-v /tmp/go-cache:/tmp/go-cache'
                }
            }
            environment {
                GOCACHE = '/tmp/go-cache'
                GOPATH = '/go'
                HOME = '/tmp'
            }
            steps {
                script {
                    // Debug: List all directories and files to understand repository structure
                    sh 'ls -la'
                    
                    // Create directory for Go cache
                    sh 'mkdir -p /tmp/go-cache'
                    sh 'chmod 777 /tmp/go-cache'
                    
                    // Check if the catalog directory exists
                    sh 'if [ -d "new-revive-catalog/catalog" ]; then echo "Directory exists"; else echo "Directory does not exist"; fi'
                    
                    // Navigate to the catalog directory
                    dir("new-revive-catalog/catalog") {
                        // Check if go.mod exists
                        sh 'if [ -f "go.mod" ]; then echo "go.mod found"; else echo "no go.mod found"; fi'
                        
                        // Display go.mod content if it exists
                        sh 'if [ -f "go.mod" ]; then cat go.mod; fi'
                        
                        // Get dependencies (with verbose output for debugging)
                        sh 'go mod download -x'
                        
                        // Build with verbose output for debugging
                        sh 'go build -v .'
                        
                        // Check if there are test files before attempting to run tests
                        sh '''
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