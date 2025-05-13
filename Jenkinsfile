pipeline {
    agent {
        label 'new-revive-agent'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 2, unit: 'HOURS')
        timestamps()
    }
    
    environment {
        SONAR_PROJECT_KEY = 'new-revive-ui'
        SONAR_PROJECT_NAME = 'New Revive UI'
    }
    
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
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
                    mvn clean compile
                '''
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
                    script {
                        // Check if test results exist before trying to publish
                        def testResultsDir = 'new-revive-ui/ui/target/surefire-reports'
                        if (fileExists(testResultsDir)) {
                            def xmlFiles = sh(
                                script: "find ${testResultsDir} -name '*.xml' 2>/dev/null || true",
                                returnStdout: true
                            ).trim()
                            
                            if (xmlFiles) {
                                junit testResults: "${testResultsDir}/**/*.xml", 
                                      allowEmptyResults: true
                            } else {
                                echo "No test results found in ${testResultsDir}"
                            }
                        } else {
                            echo "Test results directory not found: ${testResultsDir}"
                        }
                        
                        // Check if JaCoCo report exists before trying to publish
                        def jacocoDir = 'new-revive-ui/ui/target/site/jacoco'
                        if (fileExists(jacocoDir) && fileExists("${jacocoDir}/index.html")) {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: jacocoDir,
                                reportFiles: 'index.html',
                                reportName: 'JaCoCo Coverage Report'
                            ])
                        } else {
                            echo "JaCoCo report not found at ${jacocoDir}"
                        }
                    }
                }
            }
        }
        
        stage('SonarQube Analysis') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-17'
                    reuseNode true
                }
            }
            steps {
                script {
                    withSonarQubeEnv('sonar') {
                        withCredentials([string(credentialsId: 'sonarqube-jenkins-id', variable: 'SONAR_TOKEN')]) {
                            sh '''
                                cd new-revive-ui/ui
                                
                                # Use Maven for SonarQube analysis instead of standalone scanner
                                mvn sonar:sonar \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                    -Dsonar.projectName="${SONAR_PROJECT_NAME}" \
                                    -Dsonar.projectVersion=${BUILD_NUMBER} \
                                    -Dsonar.sources=src/main/java \
                                    -Dsonar.java.binaries=target/classes \
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
                    echo "Checking Quality Gate..."
                    
                    // Give SonarQube time to process
                    sleep(time: 30, unit: 'SECONDS')
                    
                    // Try manual API check instead of waitForQualityGate
                    withCredentials([string(credentialsId: 'sonarqube-jenkins-id', variable: 'SONAR_TOKEN')]) {
                        def attempts = 0
                        def maxAttempts = 10
                        def qualityGateStatus = 'PENDING'
                        
                        while (attempts < maxAttempts && qualityGateStatus == 'PENDING') {
                            attempts++
                            
                            try {
                                def response = sh(
                                    script: """
                                        curl -s -u ${SONAR_TOKEN}: \
                                        "http://18.222.118.105:9000/api/qualitygates/project_status?projectKey=${SONAR_PROJECT_KEY}"
                                    """,
                                    returnStdout: true,
                                    returnStatus: false
                                ).trim()
                                
                                echo "API Response: ${response}"
                                
                                if (response) {
                                    def json = readJSON(text: response)
                                    qualityGateStatus = json.projectStatus?.status ?: 'UNKNOWN'
                                    
                                    echo "Attempt ${attempts}/${maxAttempts}: Quality Gate Status = ${qualityGateStatus}"
                                    
                                    if (qualityGateStatus in ['OK', 'WARN', 'ERROR']) {
                                        break
                                    }
                                }
                                
                                if (attempts < maxAttempts) {
                                    sleep(time: 15, unit: 'SECONDS')
                                }
                                
                            } catch (Exception e) {
                                echo "Error checking quality gate: ${e.message}"
                                if (attempts >= maxAttempts) {
                                    qualityGateStatus = 'UNKNOWN'
                                }
                            }
                        }
                        
                        echo "Final Quality Gate Status: ${qualityGateStatus}"
                        echo "View details at: http://18.222.118.105:9000/dashboard?id=${SONAR_PROJECT_KEY}"
                        
                        // Handle the status without failing the build
                        if (qualityGateStatus == 'ERROR') {
                            unstable("Quality Gate failed but continuing pipeline")
                        } else if (qualityGateStatus == 'WARN') {
                            echo "Quality Gate has warnings"
                        } else if (qualityGateStatus == 'OK') {
                            echo "Quality Gate passed!"
                        } else {
                            echo "Quality Gate status unknown, continuing..."
                        }
                    }
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
            when {
                not {
                    equals expected: 'FAILURE', actual: currentBuild.result
                }
            }
            steps {
                sh '''
                    cd new-revive-ui/ui
                    mvn package -DskipTests
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'new-revive-ui/ui/target/*.jar', 
                                    fingerprint: true,
                                    allowEmptyArchive: true
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
            echo '✅ Pipeline executed successfully!'
            script {
                def sonarUrl = "http://18.222.118.105:9000/dashboard?id=${SONAR_PROJECT_KEY}"
                echo "SonarQube Dashboard: ${sonarUrl}"
            }
        }
        failure {
            echo '❌ Pipeline execution failed!'
            script {
                def sonarUrl = "http://18.222.118.105:9000/project/issues?id=${SONAR_PROJECT_KEY}&resolved=false"
                echo "Check Quality Issues: ${sonarUrl}"
            }
        }
        unstable {
            echo '⚠️ Pipeline execution completed with warnings!'
        }
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}