pipeline {
    agent {
        label 'new-revive-agent'
    }
    environment {
        SCANNER_HOME = tool 'sonar' // Define the SonarQube scanner tool
        DOCKERHUB_USERNAME = 'arsenet10'  // Changed to lowercase
        IMAGE_NAME = "${DOCKERHUB_USERNAME}/new-revive"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM', 
                    branches: [[name: 'asset']], 
                    doGenerateSubmoduleConfigurations: false, 
                    extensions: [], 
                    submoduleCfg: [], 
                    userRemoteConfigs: [[
                        credentialsId: 'new-revive-ssh-key',
                        url: 'https://github.com/Arsenet7/new-revive.git'
                    ]]
                ])
                
                // List workspace contents to debug
                sh 'ls -la'
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building the application...'
                
                // Find all asset or assets directories
                sh 'find . -type d -name "asset*" -ls'
                
                // Find all files in the repository
                sh 'find . -type f -not -path "*/\\.*" | sort'
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                
                withSonarQubeEnv('sonar') {
                    withCredentials([string(credentialsId: 'sonarqube-jenkins-id', variable: 'SONAR_TOKEN')]) {
                        script {
                            // Run SonarQube scanner
                            sh '''
                                ${SCANNER_HOME}/bin/sonar-scanner \
                                    -Dsonar.token=${SONAR_TOKEN} \
                                    -Dsonar.projectKey=new-revive \
                                    -Dsonar.projectName="New Revive" \
                                    -Dsonar.projectVersion=1.0 \
                                    -Dsonar.sources=. \
                                    -Dsonar.exclusions="**/node_modules/**,**/target/**,**/build/**" \
                                    -Dsonar.coverage.exclusions="**/test/**,**/tests/**"
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                echo 'Checking SonarQube Quality Gate...'
                
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Process Nginx Configuration') {
            steps {
                echo 'Processing Nginx configuration...'
                
                script {
                    def nginxConfPath = sh(script: 'find . -name "nginx.conf" | head -1', returnStdout: true).trim()
                    
                    if (nginxConfPath) {
                        echo "Found nginx.conf at: ${nginxConfPath}"
                        
                        // Create a directory to store configuration files
                        sh 'mkdir -p config_files'
                        
                        // Copy nginx.conf to the config_files directory
                        sh "cp ${nginxConfPath} config_files/"
                        
                        // Just to verify the content
                        sh "cat ${nginxConfPath}"
                        
                        echo "Nginx configuration file processed and stored in config_files directory"
                    } else {
                        error "nginx.conf not found in the workspace"
                    }
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                echo 'Preparing deployment...'
                
                script {
                    // First try to find the assets directory (with 's')
                    def assetDirPath = sh(script: 'find . -type d -name "assets" | head -1', returnStdout: true).trim()
                    
                    // If not found, try the asset directory (without 's')
                    if (!assetDirPath) {
                        assetDirPath = sh(script: 'find . -type d -name "asset" | head -1', returnStdout: true).trim()
                    }
                    
                    if (assetDirPath) {
                        echo "Found assets directory at: ${assetDirPath}"
                        
                        // Create a directory to store application files
                        sh 'mkdir -p deployment/app'
                        
                        // Copy application files to the deployment directory
                        sh "cp -r ${assetDirPath}/* deployment/app/ || echo 'Copy may have failed if directory is empty'"
                        
                        // List files in the deployment directory
                        sh 'ls -la deployment/app/'
                        
                        echo "Application files prepared for deployment in deployment/app directory"
                    } else {
                        echo "Warning: Asset directory not found, continuing anyway..."
                    }
                }
            }
        }pipeline {
    agent {
        label 'new-revive-agent'
    }

    parameters {
        booleanParam(name: 'SKIP_SONAR', defaultValue: false, description: 'Skip SonarQube analysis and quality gate check')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 2, unit: 'HOURS')
        timestamps()
    }

    environment {
        SCANNER_HOME = tool 'sonar' // Define the SonarQube scanner tool
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-ars-id')
        DOCKERHUB_USERNAME = 'arsenet10'
        DOCKER_IMAGE_ASSET = "${DOCKERHUB_USERNAME}/new-revive"
        BUILD_VERSION = "${env.BUILD_NUMBER}"
        HELM_CHART_PATH = 'helm-revive/asset'
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: 'asset']], 
                    doGenerateSubmoduleConfigurations: false, 
                    extensions: [], 
                    submoduleCfg: [], 
                    userRemoteConfigs: [[
                        credentialsId: 'new-revive-ssh-key',
                        url: 'https://github.com/Arsenet7/new-revive.git'
                    ]]
                ])
                
                // List workspace contents to debug
                sh 'ls -la'
            }
        }

        stage('Build and Prepare Assets') {
            steps {
                echo 'Building the application...'
                
                // Find all asset or assets directories
                sh 'find . -type d -name "asset*" -ls'
                
                // Find all files in the repository
                sh 'find . -type f -not -path "*/\\.*" | sort'
                
                echo 'Processing Nginx configuration...'
                script {
                    def nginxConfPath = sh(script: 'find . -name "nginx.conf" | head -1', returnStdout: true).trim()
                    
                    if (nginxConfPath) {
                        echo "Found nginx.conf at: ${nginxConfPath}"
                        
                        // Create a directory to store configuration files
                        sh 'mkdir -p config_files'
                        
                        // Copy nginx.conf to the config_files directory
                        sh "cp ${nginxConfPath} config_files/"
                        
                        // Just to verify the content
                        sh "cat ${nginxConfPath}"
                        
                        echo "Nginx configuration file processed and stored in config_files directory"
                    } else {
                        error "nginx.conf not found in the workspace"
                    }
                }
                
                echo 'Preparing deployment assets...'
                script {
                    // First try to find the assets directory (with 's')
                    def assetDirPath = sh(script: 'find . -type d -name "assets" | head -1', returnStdout: true).trim()
                    
                    // If not found, try the asset directory (without 's')
                    if (!assetDirPath) {
                        assetDirPath = sh(script: 'find . -type d -name "asset" | head -1', returnStdout: true).trim()
                    }
                    
                    if (assetDirPath) {
                        echo "Found assets directory at: ${assetDirPath}"
                        
                        // Create a directory to store application files
                        sh 'mkdir -p deployment/app'
                        
                        // Copy application files to the deployment directory
                        sh "cp -r ${assetDirPath}/* deployment/app/ || echo 'Copy may have failed if directory is empty'"
                        
                        // List files in the deployment directory
                        sh 'ls -la deployment/app/'
                        
                        echo "Application files prepared for deployment in deployment/app directory"
                    } else {
                        echo "Warning: Asset directory not found, continuing anyway..."
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression { return !params.SKIP_SONAR }
            }
            steps {
                echo 'Running SonarQube analysis...'
                
                withSonarQubeEnv('sonar') {
                    withCredentials([string(credentialsId: 'sonarqube-jenkins-id', variable: 'SONAR_TOKEN')]) {
                        script {
                            // Run SonarQube scanner
                            sh '''
                                ${SCANNER_HOME}/bin/sonar-scanner \
                                    -Dsonar.token=${SONAR_TOKEN} \
                                    -Dsonar.projectKey=new-revive-asset \
                                    -Dsonar.projectName="New Revive Asset" \
                                    -Dsonar.projectVersion=${BUILD_VERSION} \
                                    -Dsonar.sources=. \
                                    -Dsonar.exclusions="**/node_modules/**,**/target/**,**/build/**" \
                                    -Dsonar.coverage.exclusions="**/test/**,**/tests/**"
                            '''
                        }
                    }
                }
            }
        }

        stage("Quality Gate") {
            when {
                expression { return !params.SKIP_SONAR }
            }
            steps {
                echo 'Checking SonarQube Quality Gate...'
                
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                echo 'Building Docker image...'
                
                script {
                    // Find the Dockerfile
                    def dockerfilePath = sh(script: 'find . -name "Dockerfile" | head -1', returnStdout: true).trim()
                    
                    if (dockerfilePath) {
                        echo "Found Dockerfile at: ${dockerfilePath}"
                        
                        // Get the directory containing the Dockerfile
                        def dockerfileDir = sh(script: "dirname ${dockerfilePath}", returnStdout: true).trim()
                        
                        // Use Docker registry method for consistency with catalog pipeline
                        docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-ars-id') {
                            def assetImage = docker.build("${DOCKER_IMAGE_ASSET}:${BUILD_VERSION}", "-f ${dockerfilePath} ${dockerfileDir}")
                            assetImage.push()
                            assetImage.push('latest')
                        }
                        
                        echo "Docker image built and pushed successfully"
                    } else {
                        error "Dockerfile not found in the workspace"
                    }
                }
            }
        }

        stage('Update Helm Chart') {
            steps {
                script {
                    checkout([
                        $class: 'GitSCM', 
                        branches: [[name: 'main']], 
                        doGenerateSubmoduleConfigurations: false, 
                        extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'helm-repo']], 
                        submoduleCfg: [], 
                        userRemoteConfigs: [[
                            credentialsId: 'github-token-id',
                            url: 'https://github.com/Arsenet7/new-revive.git'
                        ]]
                    ])

                    dir('helm-repo') {
                        sh '''
                            git config user.name "Jenkins CI"
                            git config user.email "jenkins@company.com"
                            
                            # Create and switch to main branch to avoid detached HEAD
                            git checkout -B main origin/main
                        '''

                        sh """
                            # Update asset image tag
                            sed -i '/asset:/,/tag:/ s/tag: .*/tag: "${BUILD_VERSION}"/' ${HELM_CHART_PATH}/values.yaml || true
                            
                            # General tag replacement fallback
                            sed -i 's/tag: .*/tag: "${BUILD_VERSION}"/' ${HELM_CHART_PATH}/values.yaml
                            
                            echo "Updated Helm chart values.yaml with image tag: ${BUILD_VERSION}"
                            echo "=== Updated values.yaml content ==="
                            cat ${HELM_CHART_PATH}/values.yaml | grep -A2 -B2 "tag:"
                        """

                        script {
                            // Use GitHub token for authentication
                            withCredentials([usernamePassword(credentialsId: 'github-token-id', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_TOKEN')]) {
                                sh """
                                    # Configure Git to use the token for authentication
                                    git remote set-url origin https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/Arsenet7/new-revive.git
                                    
                                    git add ${HELM_CHART_PATH}/values.yaml
                                    
                                    # Check if there are changes to commit
                                    if git diff --staged --quiet; then
                                        echo "No changes to commit - image tag is already up to date"
                                    else
                                        git commit -m "Update asset image tag to ${BUILD_VERSION} - Build ${BUILD_NUMBER}

- Asset image: ${DOCKER_IMAGE_ASSET}:${BUILD_VERSION}

Updated by Jenkins build #${BUILD_NUMBER}"
                                        echo "Pushing changes to repository..."
                                        git push origin main
                                        echo "Successfully updated Helm chart with image tag ${BUILD_VERSION}"
                                    fi
                                """
                            }
                        }
                    }
                }
            }
            post {
                failure {
                    echo "Failed to update Helm chart. Please check Git credentials and repository permissions."
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo 'Archiving artifacts...'
                
                // Archive the config_files and deployment directories as artifacts
                archiveArtifacts artifacts: 'config_files/**/*,deployment/**/*', allowEmptyArchive: true
                
                echo "Artifacts archived successfully"
            }
        }
    }

    post {
        success {
            echo 'Build, SonarQube analysis, Docker image push, and Helm chart update completed successfully!'
            echo "Docker image available at: ${DOCKER_IMAGE_ASSET}:${BUILD_VERSION}"
        }
        failure {
            echo 'Build, SonarQube analysis, Docker image push, or Helm chart update failed!'
            
            // Archive any available logs or output
            script {
                sh 'find . -name "*.log" -o -name "*.out" | xargs tar -czf logs.tar.gz || echo "No logs found"'
                archiveArtifacts artifacts: 'logs.tar.gz', allowEmptyArchive: true
            }
        }
        always {
            // Clean up local images
            script {
                sh """
                    docker rmi ${DOCKER_IMAGE_ASSET}:${BUILD_VERSION} || true
                    docker rmi ${DOCKER_IMAGE_ASSET}:latest || true
                """
            }
            cleanWs()
        }
    }
}
        
        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                
                script {
                    // Find the Dockerfile
                    def dockerfilePath = sh(script: 'find . -name "Dockerfile" | head -1', returnStdout: true).trim()
                    
                    if (dockerfilePath) {
                        echo "Found Dockerfile at: ${dockerfilePath}"
                        
                        // Get the directory containing the Dockerfile
                        def dockerfileDir = sh(script: "dirname ${dockerfilePath}", returnStdout: true).trim()
                        
                        // Build the Docker image with lowercase username
                        sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ${dockerfileDir}"
                        
                        echo "Docker image built successfully"
                    } else {
                        error "Dockerfile not found in the workspace"
                    }
                }
            }
        }
        
        stage('Docker Push to DockerHub') {
            steps {
                echo 'Pushing Docker image to DockerHub...'
                
                script {
                    // Login and push to DockerHub
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-ars-id', 
                                                    usernameVariable: 'DOCKER_USER', 
                                                    passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "${DOCKER_PASS}" | docker login --username "${DOCKER_USER}" --password-stdin docker.io
                            docker push docker.io/${IMAGE_NAME}:${IMAGE_TAG}
                            docker push docker.io/${IMAGE_NAME}:latest
                        '''
                    }
                    
                    echo "Docker image pushed successfully to DockerHub"
                    echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    echo "Image: ${IMAGE_NAME}:latest"
                }
            }
        }
        
        stage('Archive Artifacts') {
            steps {
                echo 'Archiving artifacts...'
                
                // Archive the config_files and deployment directories as artifacts
                archiveArtifacts artifacts: 'config_files/**/*,deployment/**/*', allowEmptyArchive: true
                
                echo "Artifacts archived successfully"
            }
        }
        
        stage('Cleanup Docker Images') {
            steps {
                echo 'Cleaning up local Docker images...'
                
                script {
                    // Remove the local Docker images to save space
                    sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
                    sh "docker rmi ${IMAGE_NAME}:latest || true"
                    
                    echo "Local Docker images cleaned up"
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline executed successfully!'
            echo "Docker image available at: ${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline execution failed!'
            
            // Archive any available logs or output
            script {
                sh 'find . -name "*.log" -o -name "*.out" | xargs tar -czf logs.tar.gz || echo "No logs found"'
                archiveArtifacts artifacts: 'logs.tar.gz', allowEmptyArchive: true
            }
        }
        always {
            echo 'Cleaning workspace...'
            cleanWs(cleanWhenNotBuilt: false, deleteDirs: true, disableDeferredWipeout: true)
        }
    }
}