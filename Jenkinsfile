pipeline {
    agent {
        label 'new-revive-agent'
    }

    environment {
                SCANNER_HOME = tool 'sonar' // Define the SonarQube scanner tool
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
                    image 'maven:3.8-openjdk-17'
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
                    '''
                    archiveArtifacts artifacts: 'new-revive-ui/ui/target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Test') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-17'
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
                    '''
                }
            }
        }
        
        stage('SonarQube Analysis') {
           
            steps {
                script {
                    // Using withSonarQubeEnv wrapper to configure SonarQube environment
                    withSonarQubeEnv('sonar') {
                        // Using withCredentials to securely pass SonarQube credentials
                        withCredentials([string(credentialsId: 'sonarqube-jenkins-id', variable: 'SONAR_TOKEN')]) {
                            sh '''
                                cd new-revive-ui/ui
                                ${SCANNER_HOME}/bin/sonar-scanner \
                                    -Dsonar.projectKey=new-revive-ui \
                                    -Dsonar.projectName="New Revive UI" \
                                    -Dsonar.projectVersion=${BUILD_NUMBER} \
                                    -Dsonar.sources=src/main/java \
                                    -Dsonar.java.binaries=target/classes \
                                    -Dsonar.tests=src/test/java \
                                    -Dsonar.java.test.binaries=target/test-classes \
                                    -Dsonar.junit.reportPaths=target/surefire-reports \
                                    -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                                    -Dsonar.login=${SONAR_TOKEN}
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    // Wait for the Quality Gate result
                    timeout(time: 1, unit: 'HOURS') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
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