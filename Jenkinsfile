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
                    sh 'npm test'
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Build and tests completed successfully!'
        }
        failure {
            echo 'Build or tests failed. Check logs for details.'
        }
    }
}