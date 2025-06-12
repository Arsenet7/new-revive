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
        
        stage('Login to ArgoCD') {
            steps {
                script {
                    sh '''
                        echo "Logging into ArgoCD..."
                        argocd login $ARGOCD_SERVER \
                            --username $ARGOCD_CREDS_USR \
                            --password $ARGOCD_CREDS_PSW \
                            --insecure
                        
                        echo "Current applications:"
                        argocd app list
                    '''
                }
            }
        }
        
        stage('Update Applications Without Values File') {
            steps {
                script {
                    sh '''
                        echo "Updating applications to remove problematic values file reference..."
                        
                        # Update UI application if it exists
                        if argocd app list | grep -E "(^|/)ui($|[[:space:]])"; then
                            echo "Updating UI application..."
                            argocd app set argocd-s6arsene/ui \
                                --repo $GITHUB_REPO \
                                --path helm-revive/ui \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default || echo "Could not update UI app"
                        else
                            echo "UI application not found"
                        fi
                        
                        # Update Catalog application if it exists
                        if argocd app list | grep -E "(^|/)catalog($|[[:space:]])"; then
                            echo "Updating Catalog application..."
                            argocd app set argocd-s6arsene/catalog \
                                --repo $GITHUB_REPO \
                                --path helm-revive/catalog \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default || echo "Could not update Catalog app"
                        else
                            echo "Catalog application not found - will create it"
                            argocd app create argocd-s6arsene/catalog \
                                --repo $GITHUB_REPO \
                                --path helm-revive/catalog \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default || echo "Could not create Catalog app"
                        fi
                        
                        # Update Assets application if it exists
                        if argocd app list | grep -E "(^|/)assets($|[[:space:]])"; then
                            echo "Updating Assets application..."
                            argocd app set argocd-s6arsene/assets \
                                --repo $GITHUB_REPO \
                                --path helm-revive/assets \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default || echo "Could not update Assets app"
                        else
                            echo "Assets application not found"
                        fi
                        
                        echo "✓ All applications processed"
                    '''
                }
            }
        }
        
        stage('Enable Auto Sync') {
            steps {
                script {
                    sh '''
                        echo "Enabling auto-sync for existing applications..."
                        
                        # Get list of existing applications
                        EXISTING_APPS=$(argocd app list --output name | grep -E "(ui|catalog|assets)" || echo "")
                        
                        if [ -z "$EXISTING_APPS" ]; then
                            echo "No target applications found"
                        else
                            for app in $EXISTING_APPS; do
                                echo "Enabling auto-sync for $app..."
                                argocd app set $app --sync-policy automated --auto-prune --self-heal || echo "Could not enable auto-sync for $app (may be permission issue)"
                                sleep 2
                            done
                        fi
                    '''
                }
            }
        }
        
        stage('Sync Applications') {
            steps {
                script {
                    sh '''
                        echo "Syncing all applications..."
                        
                        for app in "argocd-s6arsene/ui" "argocd-s6arsene/catalog" "argocd-s6arsene/assets"; do
                            echo "Syncing $app..."
                            
                            if argocd app sync $app --timeout 180; then
                                echo "✓ Successfully synced $app"
                            elif argocd app sync $app --force --timeout 180; then
                                echo "✓ Force synced $app successfully"
                            else
                                echo "⚠ Could not sync $app - checking status..."
                                argocd app get $app
                            fi
                            
                            sleep 10
                        done
                    '''
                }
            }
        }
        
        stage('Wait for Deployments') {
            steps {
                script {
                    sh '''
                        echo "Waiting for deployments to complete..."
                        sleep 30
                        
                        echo "Checking final application status..."
                        EXISTING_APPS=$(argocd app list --output name | grep -E "(ui|catalog|assets)" || echo "")
                        
                        if [ ! -z "$EXISTING_APPS" ]; then
                            for app in $EXISTING_APPS; do
                                echo "=== $app ==="
                                # Try to get status, but don't fail if permission denied
                                if argocd app get $app --output wide 2>/dev/null; then
                                    echo "✓ Status retrieved successfully"
                                else
                                    echo "⚠ Could not get status (permission issue)"
                                fi
                                echo ""
                            done
                        fi
                    '''
                }
            }
        }
        
        stage('Final Status Report') {
            steps {
                script {
                    sh '''
                        echo "=== FINAL DEPLOYMENT REPORT ==="
                        argocd app list
                        
                        echo ""
                        echo "=== HEALTH CHECK ==="
                        HEALTHY_COUNT=0
                        TOTAL_COUNT=0
                        
                        for app in "argocd-s6arsene/ui" "argocd-s6arsene/catalog" "argocd-s6arsene/assets"; do
                            TOTAL_COUNT=$((TOTAL_COUNT + 1))
                            
                            if argocd app get $app | grep -q "Health Status:.*Healthy"; then
                                echo "✅ $app is HEALTHY"
                                HEALTHY_COUNT=$((HEALTHY_COUNT + 1))
                            elif argocd app get $app | grep -q "Health Status:.*Progressing"; then
                                echo "🔄 $app is PROGRESSING"
                            else
                                echo "❌ $app has issues"
                                argocd app get $app | grep -E "(Health Status|Sync Status|MESSAGE)"
                            fi
                        done
                        
                        echo ""
                        echo "=== SUMMARY ==="
                        echo "Healthy applications: $HEALTHY_COUNT/$TOTAL_COUNT"
                        
                        if [ $HEALTHY_COUNT -eq $TOTAL_COUNT ]; then
                            echo "🎉 ALL APPLICATIONS ARE HEALTHY!"
                        elif [ $HEALTHY_COUNT -gt 0 ]; then
                            echo "⚠️  Some applications need attention"
                        else
                            echo "❌ All applications need troubleshooting"
                            echo ""
                            echo "Common fixes:"
                            echo "1. Check if namespace 's6arserne' exists: kubectl get namespace s6arserne"
                            echo "2. Create namespace manually: kubectl create namespace s6arserne"
                            echo "3. Check Helm chart validity in repository"
                            echo "4. Verify values.yaml files exist in each chart directory"
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline completed successfully!"
            echo ""
            echo "✅ Next Steps:"
            echo "1. Check ArgoCD UI: http://134.122.119.201:32129"
            echo "2. Verify applications are healthy and synced"
            echo "3. Check pods in namespace: kubectl get pods -n s6arserne"
            echo "4. Applications will auto-sync when you push changes to repository"
        }
        failure {
            echo "❌ Pipeline failed"
            echo "Check the logs above for specific errors"
        }
        always {
            script {
                sh 'argocd logout $ARGOCD_SERVER 2>/dev/null || true'
            }
        }
    }
}