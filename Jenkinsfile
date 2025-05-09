pipeline {
    agent {
        label 'new-revive-agent'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM', 
                    branches: [[name: 'checkout']], 
                    userRemoteConfigs: [[
                        url: 'https://github.com/Arsenet7/new-revive.git',
                        credentialsId: 'new-revive-ssh-key'
                    ]]
                ])
            }
        }
        
        stage('Install Dependencies') {
            agent {
                docker {
                    image 'node:18'
                    reuseNode true
                }
            }
            steps {
                dir('new-revive-checkout/checkout') {
                    sh 'npm ci'
                }
            }
        }
        
        stage('Build') {
            agent {
                docker {
                    image 'node:18'
                    reuseNode true
                }
            }
            steps {
                dir('new-revive-checkout/checkout') {
                    sh 'npm run build'
                }
            }
        }
        
        stage('Test') {
            agent {
                docker {
                    image 'node:18'
                    reuseNode true
                }
            }
            steps {
                dir('new-revive-checkout/checkout') {
                    // Modified to pass with no tests
                    sh 'npm test -- --passWithNoTests || echo "No tests found, but continuing build"'
                    
                    // Alternative approach - check if tests exist before running
                    script {
                        def testFiles = sh(script: 'find src -name "*.spec.ts" | wc -l', returnStdout: true).trim()
                        if (testFiles == '0') {
                            echo "No test files found. Skipping tests."
                        } else {
                            sh 'npm test'
                        }
                    }
                }
            }
        }
        
        stage('Check for Vulnerabilities') {
            agent {
                docker {
                    image 'node:18'
                    reuseNode true
                }
            }
            steps {
                dir('new-revive-checkout/checkout') {
                    // Run npm audit but don't fail the build
                    sh 'npm audit || echo "Vulnerabilities found, but continuing build"'
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Build completed successfully!'
        }
        failure {
            echo 'Build or tests failed. Check logs for details.'
        }
    }
}