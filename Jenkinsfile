pipeline {
    agent {
        label 'new-revive-agent'
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
            echo 'Pipeline executed successfully!'
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