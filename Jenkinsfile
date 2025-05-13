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
        SCANNER_HOME = tool 'sonar' // Define the SonarQube scanner tool
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
                    args '-e JAVA_HOME=/opt/java/openjdk'
                }
            }
            steps {
                dir('new-revive-ui/ui') {
                    sh '''
                        echo "JAVA_HOME is: $JAVA_HOME"
                        java -version
                        mvn --version
                        mvn clean install -DskipTests
                    '''
                }
            }
        }
        
        stage('Test with Coverage') {
            agent {
                docker {
                    image 'maven:3.8-openjdk-17'
                    reuseNode true
                    args '-e JAVA_HOME=/opt/java/openjdk'
                }
            }
            steps {
                dir('new-revive-ui/ui') {
                    sh 'mvn test'
                }
            }
            post {
                always {
                    junit 'new-revive-ui/ui/target/surefire-reports/**/*.xml'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'new-revive-ui/ui/target/site/jacoco',
                        reportFiles: 'index.html',
                        reportName: 'JaCoCo Coverage Report'
                    ])
                }
            }
        }
        
        stage('Static Code Analysis') {
            parallel {
                stage('Checkstyle') {
                    agent {
                        docker {
                            image 'maven:3.8-openjdk-17'
                            reuseNode true
                            args '-e JAVA_HOME=/opt/java/openjdk'
                        }
                    }
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            dir('new-revive-ui/ui') {
                                sh 'mvn checkstyle:check || true'
                            }
                        }
                    }
                }
                stage('PMD') {
                    agent {
                        docker {
                            image 'maven:3.8-openjdk-17'
                            reuseNode true
                            args '-e JAVA_HOME=/opt/java/openjdk'
                        }
                    }
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            dir('new-revive-ui/ui') {
                                sh 'mvn pmd:pmd || true'
                            }
                        }
                    }
                }
                stage('SpotBugs') {
                    agent {
                        docker {
                            image 'maven:3.8-openjdk-17'
                            reuseNode true
                            args '-e JAVA_HOME=/opt/java/openjdk'
                        }
                    }
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            dir('new-revive-ui/ui') {
                                sh 'mvn spotbugs:check || true'
                            }
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
                    args '-e JAVA_HOME=/opt/java/openjdk'
                }
            }
            steps {
                script {
                    withSonarQubeEnv('sonar') {
                        withCredentials([string(credentialsId: 'sonarqube-jenkins-id', variable: 'SONAR_TOKEN')]) {
                            dir('new-revive-ui/ui') {
                                sh """
                                    mvn sonar:sonar \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                    -Dsonar.projectName="${SONAR_PROJECT_NAME}" \
                                    -Dsonar.projectVersion=${BUILD_NUMBER} \
                                    -Dsonar.sources=src/main/java \
                                    -Dsonar.java.binaries=target/classes \
                                    -Dsonar.tests=src/test/java \
                                    -Dsonar.java.test.binaries=target/test-classes \
                                    -Dsonar.junit.reportPaths=target/surefire-reports \
                                    -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                                    -Dsonar.language=java \
                                    -Dsonar.java.coveragePlugin=jacoco \
                                    -Dsonar.exclusions=**/*Test.java,**/*Config.java,**/model/**,**/entity/** \
                                    -Dsonar.test.inclusions=**/*Test.java \
                                    -Dsonar.dynamicAnalysis=reuseReports \
                                    -Dsonar.checkstyle.reportPaths=target/checkstyle-result.xml \
                                    -Dsonar.pmd.reportPaths=target/pmd.xml \
                                    -Dsonar.spotbugs.reportPaths=target/spotbugsXml.xml \
                                    -Dsonar.login=${SONAR_TOKEN}
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage("Quality Gate") {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
    
    post {
        success {
            echo 'Build, tests, and SonarQube analysis completed successfully!'
        }
        failure {
            echo 'Build, tests, or SonarQube analysis failed!'
        }
        always {
            cleanWs()
        }
    }
}