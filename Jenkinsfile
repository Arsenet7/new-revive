pipeline {
    agent {
        label 'new-revive-agent'
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Clean workspace before checkout
                cleanWs()
                
                // Checkout specific branch from GitHub repository using SSH credentials
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/orders']],
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
        
        stage('Build and Test') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-17'
                    reuseNode true
                }
            }
            steps {
                echo 'Building the project with Maven...'
                dir('revive-orders/orders') {
                    sh 'mvn clean compile'
                    
                    echo 'Running Maven tests...'
                    sh 'mvn test'
                    
                    echo 'Packaging the application...'
                    sh 'mvn package -DskipTests'
                }
            }
            post {
                success {
                    dir('revive-orders/orders') {
                        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                        junit 'target/surefire-reports/*.xml'
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying the application...'
                // Add your deployment commands here
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
    }
}