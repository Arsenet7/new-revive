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
                sh '''
                    cd new-revive-ui/ui
                    mvn clean package
                '''
            }
            post {
                success {
                    sh '''
                        cd new-revive-ui/ui
                        find target -name "*.jar" -type f -exec cp {} ${WORKSPACE} \;
                    '''
                    archiveArtifacts artifacts: '*.jar', fingerprint: true
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
                sh '''
                    cd new-revive-ui/ui
                    mvn test
                '''
            }
            post {
                always {
                    sh '''
                        cd new-revive-ui/ui
                        mkdir -p ${WORKSPACE}/test-reports
                        find target/surefire-reports -name "*.xml" -type f -exec cp {} ${WORKSPACE}/test-reports \;
                    '''
                    junit 'test-reports/*.xml'
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