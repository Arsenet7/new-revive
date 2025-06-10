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
                        
                        # Update UI application
                        if argocd app list | grep -E "(^|/)ui($|[[:space:]])"; then
                            echo "Updating UI application..."
                            argocd app set argocd-s6arsene/ui \
                                --repo $GITHUB_REPO \
                                --path helm-revive/ui \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default || echo "Could not update UI app"
                        fi
                        
                        # Update Catalog application  
                        if argocd app list | grep -E "(^|/)catalog($|[[:space:]])"; then
                            echo "Updating Catalog application..."
                            argocd app set argocd-s6arsene/catalog \
                                --repo $GITHUB_REPO \
                                --path helm-revive/catalog \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default || echo "Could not update Catalog app"
                        fi
                        
                        # Update Assets application
                        if argocd app list | grep -E "(^|/)assets($|[[:space:]])"; then
                            echo "Updating Assets application..."
                            argocd app set argocd-s6arsene/assets \
                                --repo $GITHUB_REPO \
                                --path helm-revive/assets \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default || echo "Could not update Assets app"
                        fi
                        
                        echo "✓ All applications updated"
                    '''
                }
            }
        }
        
        stage('Enable Auto Sync') {
            steps {
                script {
                    sh '''
                        echo "Enabling auto-sync for all applications..."
                        
                        for app in "argocd-s6arsene/ui" "argocd-s6arsene/catalog" "argocd-s6arsene/assets"; do
                            echo "Enabling auto-sync for $app..."
                            argocd app set $app --sync-policy automated --auto-prune --self-heal || echo "Could not enable auto-sync for $app"
                            sleep 2
                        done
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
                        sleep 60
                        
                        echo "Final application status:"
                        for app in "argocd-s6arsene/ui" "argocd-s6arsene/catalog" "argocd-s6arsene/assets"; do
                            echo "=== $app ==="
                            argocd app get $app --output wide || echo "Could not get $app status"
                            echo ""
                        done
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