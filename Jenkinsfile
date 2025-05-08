pipeline {
    agent {
        label 'new-revive-agent'
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Clean workspace before checkout
                cleanWs()
                
                // Checkout the repository using the credential ID
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: 'ui']], 
                    doGenerateSubmoduleConfigurations: false, 
                    extensions: [], 
                    submoduleCfg: [], 
                    userRemoteConfigs: [[
                        credentialsId: 'new-revive-ssh-key',
                        url: 'https://github.com/Arsenet7/new-revive.git'
                    ]]
                ])
            }
        }
        
        stage('Build with Maven') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-11'
                    reuseNode true
                }
            }
            steps {
                sh 'mvn --version'
                sh 'mvn clean package'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Test') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-11'
                    reuseNode true
                }
            }
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying the application...'
                // Add your deployment steps here
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline execution failed!'
        }
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}