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
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building the application...'
                // Add any build commands here for your application in new-revive-asset/asset
                dir('new-revive-asset/asset') {
                    sh 'ls -la'  // List files to verify checkout
                    // Add compilation or build steps if needed
                }
            }
        }
        
        stage('Nginx Configuration') {
            steps {
                echo 'Handling Nginx configuration...'
                
                // Validate nginx configuration
                sh 'nginx -t -c ${WORKSPACE}/nginx.conf || echo "Nginx config test failed but continuing"'
                
                // Backup existing nginx.conf if it exists
                sh 'if [ -f /etc/nginx/nginx.conf ]; then sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d%H%M%S); fi'
                
                // Copy nginx.conf to nginx config directory
                sh 'sudo cp ${WORKSPACE}/nginx.conf /etc/nginx/nginx.conf'
                
                // Reload nginx to apply changes
                sh 'sudo nginx -s reload || sudo service nginx restart'
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying the application...'
                // Deploy the application from new-revive-asset/asset
                dir('new-revive-asset/asset') {
                    // Add deployment commands here
                    // For example:
                    sh 'sudo cp -r . /var/www/new-revive/'
                    sh 'sudo chown -R www-data:www-data /var/www/new-revive/'
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