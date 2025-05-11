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
                sh 'find . -name "nginx.conf" || echo "nginx.conf not found"'
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building the application...'
                
                // Check if the application directory exists
                sh 'if [ -d "new-revive-asset/asset" ]; then echo "Directory found"; else echo "Directory not found"; fi'
                
                // Build application if directory exists
                script {
                    if (fileExists('new-revive-asset/asset')) {
                        dir('new-revive-asset/asset') {
                            sh 'ls -la'  // List files to verify checkout
                            // Add compilation or build steps if needed
                        }
                    } else {
                        echo "Warning: Application directory not found, checking alternative locations..."
                        sh 'find . -type d -name "asset" || echo "No asset directory found"'
                    }
                }
            }
        }
        
        stage('Nginx Configuration') {
            steps {
                echo 'Handling Nginx configuration...'
                
                // Find nginx.conf file first
                script {
                    def nginxConfPath = sh(script: 'find . -name "nginx.conf" | head -1', returnStdout: true).trim()
                    
                    if (nginxConfPath) {
                        echo "Found nginx.conf at: ${nginxConfPath}"
                        
                        // Check if nginx is installed
                        def nginxInstalled = sh(script: 'which nginx || echo "not installed"', returnStdout: true).trim()
                        
                        if (nginxInstalled != "not installed") {
                            // Validate nginx configuration if nginx is installed
                            sh "nginx -t -c ${nginxConfPath} || echo 'Nginx config test failed but continuing'"
                        } else {
                            echo "Nginx not installed, skipping validation"
                        }
                        
                        // Backup existing nginx.conf if it exists
                        sh 'if [ -f /etc/nginx/nginx.conf ]; then sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d%H%M%S); fi'
                        
                        // Copy nginx.conf to nginx config directory
                        sh "sudo cp ${nginxConfPath} /etc/nginx/nginx.conf"
                        
                        // Try to reload nginx
                        sh 'sudo service nginx reload || sudo service nginx restart || echo "Failed to restart nginx, may not be installed"'
                    } else {
                        error "nginx.conf not found in the workspace"
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying the application...'
                
                // Find asset directory
                script {
                    def assetDirPath = sh(script: 'find . -type d -name "asset" | head -1', returnStdout: true).trim()
                    
                    if (assetDirPath) {
                        echo "Found asset directory at: ${assetDirPath}"
                        
                        // Deploy the application from the found asset directory
                        dir(assetDirPath) {
                            sh 'ls -la'  // List files in the asset directory
                            
                            // Create destination directory if it doesn't exist
                            sh 'sudo mkdir -p /var/www/new-revive/'
                            
                            // Copy application files
                            sh 'sudo cp -r . /var/www/new-revive/'
                            
                            // Set appropriate permissions
                            sh 'sudo chown -R www-data:www-data /var/www/new-revive/ || echo "Failed to set permissions, www-data user might not exist"'
                        }
                    } else {
                        error "Asset directory not found in the workspace"
                    }
                }
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