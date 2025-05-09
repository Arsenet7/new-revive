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
                script {
                    // Debug: List all directories and files to understand repository structure
                    sh 'ls -la'
                    
                    // Check if the catalog directory exists
                    sh 'if [ -d "new-revive-catalog/catalog" ]; then echo "Directory exists"; else echo "Directory does not exist"; fi'
                    sh 'if [ -d "catalog" ]; then echo "Catalog at root exists"; else echo "Catalog at root does not exist"; fi'
                    
                    // Determine the path to the catalog directory
                    def catalogPath = sh(script: 'find . -name "catalog" -type d | head -1', returnStdout: true).trim()
                    
                    if (catalogPath) {
                        echo "Found catalog directory at: ${catalogPath}"
                        
                        dir("${catalogPath}") {
                            // Check if go.mod exists
                            def hasGoMod = sh(script: 'if [ -f "go.mod" ]; then echo "true"; else echo "false"; fi', returnStdout: true).trim()
                            
                            if (hasGoMod == "true") {
                                echo "go.mod found, proceeding with build"
                                // Get dependencies
                                sh 'go mod download'
                                
                                // Build specifically the catalog code
                                sh 'go build -v .'
                                
                                // Test specifically the catalog code
                                sh 'go test -v .'
                            } else {
                                echo "No go.mod found, initializing a new module"
                                // Initialize a new Go module if one doesn't exist
                                sh 'go mod init github.com/Arsenet7/new-revive/catalog'
                                
                                // Check for any dependencies
                                sh 'go mod tidy'
                                
                                // Build
                                sh 'go build -v .'
                                
                                // Test only if there are test files
                                sh 'if ls *_test.go 1> /dev/null 2>&1; then go test -v .; else echo "No test files found"; fi'
                            }
                        }
                    } else {
                        error "Could not find catalog directory"
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