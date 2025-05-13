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
        
        stage('SonarQube Analysis') {
            steps {
                dir('new-revive-checkout/checkout') {
                    script {
                        withSonarQubeEnv('sonar') {
                            withCredentials([string(credentialsId: 'sonarqube-jenkins-id', variable: 'SONAR_TOKEN')]) {
                                sh '''
                                    ${SCANNER_HOME}/bin/sonar-scanner \
                                    -Dsonar.projectKey=new-revive \
                                    -Dsonar.projectName="New Revive" \
                                    -Dsonar.projectVersion=1.0 \
                                    -Dsonar.sources=src \
                                    -Dsonar.tests=src \
                                    -Dsonar.test.inclusions="**/*.spec.ts" \
                                    -Dsonar.exclusions="**/node_modules/**,**/dist/**,**/coverage/**" \
                                    -Dsonar.typescript.lcov.reportPaths=coverage/lcov.info \
                                    -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                                    -Dsonar.login=$SONAR_TOKEN
                                '''
                            }
                        }
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    // Wait for the Quality Gate result
                    def qualitygate = waitForQualityGate()
                    
                    if (qualitygate.status != 'OK') {
                        error "Pipeline aborted due to quality gate failure: ${qualitygate.status}"
                    }
                    
                    echo "Quality Gate passed with status: ${qualitygate.status}"
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