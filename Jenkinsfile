pipeline {
    agent any
    
    environment {
        ARGOCD_SERVER = '134.122.119.201:32129'
        ARGOCD_CREDS = credentials('argocd-credential')
        GITHUB_REPO = 'https://github.com/Arsenet7/new-revive.git'
        TARGET_NAMESPACE = 's6arsene'
    }
    
    stages {
        stage('Install ArgoCD CLI') {
            steps {
                script {
                    sh '''
                        if ! command -v argocd &> /dev/null; then
                            echo "Installing ArgoCD CLI..."
                            curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                            chmod +x argocd
                            sudo mv argocd /usr/local/bin/argocd
                        fi
                        argocd version --client
                    '''
                }
            }
        }
        
        stage('Get ArgoCD Token') {
            steps {
                script {
                    env.ARGOCD_TOKEN = sh(
                        script: '''
                            # Login and get token
                            argocd login $ARGOCD_SERVER \
                                --username $ARGOCD_CREDS_USR \
                                --password $ARGOCD_CREDS_PSW \
                                --insecure
                            
                            # Get auth token
                            argocd account get-user-info --output json | grep -o '"iat":[0-9]*' | cut -d':' -f2 || echo ""
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    // Alternative: get session token
                    env.ARGOCD_SESSION = sh(
                        script: '''
                            curl -k -X POST https://$ARGOCD_SERVER/api/v1/session \
                                -H "Content-Type: application/json" \
                                -d '{"username":"'$ARGOCD_CREDS_USR'","password":"'$ARGOCD_CREDS_PSW'"}' \
                                | grep -o '"token":"[^"]*"' | cut -d'"' -f4 || echo ""
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    echo "Session token obtained: ${env.ARGOCD_SESSION ? 'Yes' : 'No'}"
                }
            }
        }
        
        stage('Create Applications via API') {
            steps {
                script {
                    def apps = [
                        [name: 'ui', path: 'helm-revive/ui'],
                        [name: 'catalog', path: 'helm-revive/catalog'],
                        [name: 'assets', path: 'helm-revive/assets']
                    ]
                    
                    apps.each { app ->
                        def appSpec = [
                            apiVersion: 'argoproj.io/v1alpha1',
                            kind: 'Application',
                            metadata: [
                                name: app.name,
                                namespace: 'argocd'
                            ],
                            spec: [
                                project: 'default',
                                source: [
                                    repoURL: env.GITHUB_REPO,
                                    targetRevision: 'HEAD',
                                    path: app.path,
                                    helm: [
                                        valueFiles: ['values.yaml']
                                    ]
                                ],
                                destination: [
                                    server: 'https://kubernetes.default.svc',
                                    namespace: env.TARGET_NAMESPACE
                                ],
                                syncPolicy: [
                                    syncOptions: ['CreateNamespace=true'],
                                    automated: [
                                        prune: true,
                                        selfHeal: true
                                    ]
                                ]
                            ]
                        ]
                        
                        def jsonPayload = writeJSON returnText: true, json: appSpec
                        
                        script {
                            sh """
                                echo "Creating/updating application: ${app.name}"
                                
                                # Try to create the application
                                HTTP_CODE=\$(curl -k -w "%{http_code}" -o response.json -X POST \\
                                    https://$ARGOCD_SERVER/api/v1/applications \\
                                    -H "Authorization: Bearer $ARGOCD_SESSION" \\
                                    -H "Content-Type: application/json" \\
                                    -d '${jsonPayload}')
                                
                                echo "HTTP Response Code: \$HTTP_CODE"
                                cat response.json || echo "No response body"
                                
                                # If application already exists (409), try to update it
                                if [ "\$HTTP_CODE" = "409" ]; then
                                    echo "Application exists, attempting to update..."
                                    HTTP_CODE=\$(curl -k -w "%{http_code}" -o response.json -X PUT \\
                                        https://$ARGOCD_SERVER/api/v1/applications/${app.name} \\
                                        -H "Authorization: Bearer $ARGOCD_SESSION" \\
                                        -H "Content-Type: application/json" \\
                                        -d '${jsonPayload}')
                                    echo "Update HTTP Response Code: \$HTTP_CODE"
                                    cat response.json || echo "No response body"
                                fi
                                
                                # Check if successful (2xx response)
                                if [[ "\$HTTP_CODE" =~ ^2[0-9][0-9]\$ ]]; then
                                    echo "✓ Successfully processed ${app.name}"
                                else
                                    echo "✗ Failed to process ${app.name}"
                                fi
                            """
                        }
                        
                        sleep(2) // Small delay between applications
                    }
                }
            }
        }
        
        stage('Wait for Applications to Initialize') {
            steps {
                script {
                    sh '''
                        echo "Waiting 30 seconds for applications to initialize..."
                        sleep 30
                    '''
                }
            }
        }
        
        stage('Trigger Sync via API') {
            steps {
                script {
                    def apps = ['ui', 'catalog', 'assets']
                    
                    apps.each { app ->
                        script {
                            sh """
                                echo "Triggering sync for ${app}..."
                                
                                HTTP_CODE=\$(curl -k -w "%{http_code}" -o sync_response.json -X POST \\
                                    https://$ARGOCD_SERVER/api/v1/applications/${app}/sync \\
                                    -H "Authorization: Bearer $ARGOCD_SESSION" \\
                                    -H "Content-Type: application/json" \\
                                    -d '{"prune": true, "dryRun": false}')
                                
                                echo "Sync HTTP Response Code for ${app}: \$HTTP_CODE"
                                cat sync_response.json || echo "No sync response body"
                                
                                if [[ "\$HTTP_CODE" =~ ^2[0-9][0-9]\$ ]]; then
                                    echo "✓ Successfully triggered sync for ${app}"
                                else
                                    echo "✗ Failed to trigger sync for ${app}"
                                fi
                            """
                        }
                        sleep(5)
                    }
                }
            }
        }
        
        stage('Monitor Deployment Status') {
            steps {
                script {
                    sh '''
                        echo "Monitoring deployment status..."
                        
                        for app in ui catalog assets; do
                            echo "Checking status of $app..."
                            
                            for i in {1..12}; do  # Check for 2 minutes
                                HTTP_CODE=$(curl -k -w "%{http_code}" -o status.json -X GET \\
                                    https://$ARGOCD_SERVER/api/v1/applications/$app \\
                                    -H "Authorization: Bearer $ARGOCD_SESSION")
                                
                                if [ "$HTTP_CODE" = "200" ]; then
                                    SYNC_STATUS=$(cat status.json | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "Unknown")
                                    HEALTH_STATUS=$(cat status.json | grep -o '"status":"[^"]*"' | tail -1 | cut -d'"' -f4 || echo "Unknown")
                                    
                                    echo "$app - Sync: $SYNC_STATUS, Health: $HEALTH_STATUS"
                                    
                                    if [ "$SYNC_STATUS" = "Synced" ] && [ "$HEALTH_STATUS" = "Healthy" ]; then
                                        echo "✓ $app is deployed successfully"
                                        break
                                    fi
                                else
                                    echo "Could not get status for $app (HTTP: $HTTP_CODE)"
                                fi
                                
                                if [ $i -eq 12 ]; then
                                    echo "⚠ $app deployment timed out"
                                else
                                    sleep 10
                                fi
                            done
                        done
                    '''
                }
            }
        }
        
        stage('Final Status Report') {
            steps {
                script {
                    sh '''
                        echo "=== Final Deployment Status ==="
                        
                        # Login with CLI for final status check
                        argocd login $ARGOCD_SERVER \
                            --username $ARGOCD_CREDS_USR \
                            --password $ARGOCD_CREDS_PSW \
                            --insecure
                        
                        echo "Applications in ArgoCD:"
                        argocd app list | grep -E "(ui|catalog|assets)" || echo "No matching applications found"
                        
                        argocd logout $ARGOCD_SERVER
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 Automated deployment completed successfully!"
            echo "All applications should now be deployed to the s6arsene namespace"
        }
        failure {
            echo "❌ Automated deployment failed"
            echo "Check the logs above for specific errors"
        }
        always {
            script {
                sh '''
                    # Cleanup
                    rm -f response.json sync_response.json status.json || true
                    argocd logout $ARGOCD_SERVER || true
                '''
            }
        }
    }
}