pipeline {
    agent {
        label 'new-revive-agent'
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Clean workspace before checkout
                cleanWs()
                
                // Git checkout using the provided credentials
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: 'cart']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Arsenet7/new-revive.git',
                        credentialsId: 'new-revive-ssh-key'
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
                dir('new-revive-cart/cart') {
                    sh 'mvn clean install -DskipTests'
                }
            }
        }
        
        stage('Test with Maven') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-17'
                    reuseNode true
                }
            }
            steps {
                dir('new-revive-cart/cart') {
                    sh 'mvn test'
                }
            }
        }
        
        stage('Package') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-17'
                    reuseNode true
                }
            }
            steps {
                dir('new-revive-cart/cart') {
                    sh 'mvn package'
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline executed successfully!'
            archiveArtifacts artifacts: '/new-revive-cart/cart/target/*.jar', fingerprint: true
        }
        failure {
            echo 'Pipeline execution failed!'
        }
        always {
            echo 'Pipeline execution completed.'
            // Clean up Docker containers if needed
            sh 'docker system prune -f'
        }
    }
}