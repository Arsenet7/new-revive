pipeline {
    agent any
    
    environment {
        ARGOCD_SERVER = '134.122.119.201:32129'
        ARGOCD_CREDS = credentials('argocd-credential')
        GITHUB_REPO = 'https://github.com/Arsenet7/new-revive.git'
        TARGET_NAMESPACE = 's6arserne'
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
        
        stage('Login and Investigate ArgoCD Setup') {
            steps {
                script {
                    sh '''
                        echo "Logging into ArgoCD..."
                        argocd login $ARGOCD_SERVER \
                            --username $ARGOCD_CREDS_USR \
                            --password $ARGOCD_CREDS_PSW \
                            --insecure
                        
                        echo "=== Current ArgoCD Setup ==="
                        echo "Available projects:"
                        argocd proj list || echo "Could not list projects"
                        
                        echo ""
                        echo "Default project details:"
                        argocd proj get default || echo "Could not get default project details"
                        
                        echo ""
                        echo "Existing applications:"
                        argocd app list || echo "Could not list applications"
                        
                        echo ""
                        echo "User permissions:"
                        argocd account get-user-info || echo "Could not get user info"
                        
                        echo ""
                        echo "Checking if we can create apps in default project..."
                        echo "This will help diagnose the 'app is not allowed in project default' error"
                    '''
                }
            }
        }
        
        stage('Set Project to Default') {
            steps {
                script {
                    env.ARGOCD_PROJECT = 'default'
                    echo "Using ArgoCD project: ${env.ARGOCD_PROJECT}"
                }
            }
        }
        
        stage('Create UI Application') {
            steps {
                script {
                    sh '''
                        echo "Creating UI application in default project..."
                        
                        # Check if UI application already exists
                        if argocd app list | grep -E "(^|/)ui($|[[:space:]])"; then
                            echo "UI application already exists, attempting to update..."
                            if argocd app set ui \
                                --repo $GITHUB_REPO \
                                --path helm-revive/ui \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default \
                                --values-literal-file values.yaml; then
                                echo "✓ Successfully updated UI application"
                            else
                                echo "✗ Failed to update UI application"
                                echo "This may be due to permissions or project restrictions"
                            fi
                        else
                            echo "Creating new UI application..."
                            if argocd app create ui \
                                --repo $GITHUB_REPO \
                                --path helm-revive/ui \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default \
                                --values-literal-file values.yaml; then
                                echo "✓ Successfully created UI application"
                            else
                                echo "✗ Failed to create UI application"
                                echo "Error details above - this may need manual creation"
                            fi
                        fi
                        
                        # Verify creation
                        sleep 3
                        if argocd app get ui >/dev/null 2>&1; then
                            echo "✓ UI application exists and is accessible"
                        else
                            echo "✗ UI application not found after creation attempt"
                        fi
                    '''
                }
            }
        }
        
        stage('Create Catalog Application') {
            steps {
                script {
                    sh '''
                        echo "Creating Catalog application in default project..."
                        
                        # Check if Catalog application already exists
                        if argocd app list | grep -E "(^|/)catalog($|[[:space:]])"; then
                            echo "Catalog application already exists, attempting to update..."
                            if argocd app set catalog \
                                --repo $GITHUB_REPO \
                                --path helm-revive/catalog \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default \
                                --values-literal-file values.yaml; then
                                echo "✓ Successfully updated Catalog application"
                            else
                                echo "✗ Failed to update Catalog application"
                            fi
                        else
                            echo "Creating new Catalog application..."
                            if argocd app create catalog \
                                --repo $GITHUB_REPO \
                                --path helm-revive/catalog \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default \
                                --values-literal-file values.yaml; then
                                echo "✓ Successfully created Catalog application"
                            else
                                echo "✗ Failed to create Catalog application"
                            fi
                        fi
                        
                        # Verify creation
                        sleep 3
                        if argocd app get catalog >/dev/null 2>&1; then
                            echo "✓ Catalog application exists and is accessible"
                        else
                            echo "✗ Catalog application not found after creation attempt"
                        fi
                    '''
                }
            }
        }
        
        stage('Create Assets Application') {
            steps {
                script {
                    sh '''
                        echo "Creating Assets application in default project..."
                        
                        # Check if Assets application already exists
                        if argocd app list | grep -E "(^|/)assets($|[[:space:]])"; then
                            echo "Assets application already exists, attempting to update..."
                            if argocd app set assets \
                                --repo $GITHUB_REPO \
                                --path helm-revive/assets \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default \
                                --values-literal-file values.yaml; then
                                echo "✓ Successfully updated Assets application"
                            else
                                echo "✗ Failed to update Assets application"
                            fi
                        else
                            echo "Creating new Assets application..."
                            if argocd app create assets \
                                --repo $GITHUB_REPO \
                                --path helm-revive/assets \
                                --dest-server https://kubernetes.default.svc \
                                --dest-namespace $TARGET_NAMESPACE \
                                --project default \
                                --values-literal-file values.yaml; then
                                echo "✓ Successfully created Assets application"
                            else
                                echo "✗ Failed to create Assets application"
                            fi
                        fi
                        
                        # Verify creation
                        sleep 3
                        if argocd app get assets >/dev/null 2>&1; then
                            echo "✓ Assets application exists and is accessible"
                        else
                            echo "✗ Assets application not found after creation attempt"
                        fi
                    '''
                }
            }
        }
        
        stage('Enable Auto Sync') {
            steps {
                script {
                    sh '''
                        echo "Attempting to enable auto-sync for applications..."
                        
                        for app in ui catalog assets; do
                            if argocd app get $app >/dev/null 2>&1; then
                                echo "Enabling auto-sync for $app..."
                                argocd app set $app --sync-policy automated --auto-prune --self-heal || echo "Could not enable auto-sync for $app"
                            else
                                echo "Skipping auto-sync for $app (application not found)"
                            fi
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
                        echo "Attempting to sync applications..."
                        
                        for app in ui catalog assets; do
                            if argocd app get $app >/dev/null 2>&1; then
                                echo "Syncing $app..."
                                
                                # Try multiple sync approaches
                                if argocd app sync $app --timeout 120; then
                                    echo "✓ Successfully synced $app"
                                elif argocd app sync $app --force --timeout 120; then
                                    echo "✓ Force synced $app successfully"
                                else
                                    echo "⚠ Could not sync $app"
                                fi
                            else
                                echo "Skipping sync for $app (application not found)"
                            fi
                            
                            sleep 10
                        done
                    '''
                }
            }
        }
        
        stage('Refresh and Wait') {
            steps {
                script {
                    sh '''
                        echo "Refreshing applications to detect repository changes..."
                        
                        for app in ui catalog assets; do
                            if argocd app get $app >/dev/null 2>&1; then
                                echo "Refreshing $app..."
                                argocd app refresh $app || echo "Could not refresh $app"
                            fi
                            sleep 5
                        done
                        
                        echo "Waiting 30 seconds for operations to complete..."
                        sleep 30
                    '''
                }
            }
        }
        
        stage('Final Status Report') {
            steps {
                script {
                    sh '''
                        echo "=== Final Status Report ==="
                        echo "Current applications in ArgoCD:"
                        argocd app list
                        
                        echo ""
                        echo "=== Target Applications Status ==="
                        for app in ui catalog assets; do
                            echo "--- $app ---"
                            if argocd app get $app 2>/dev/null; then
                                echo "✓ $app exists and is accessible"
                            else
                                echo "✗ $app not found or inaccessible"
                            fi
                            echo ""
                        done
                        
                        echo "=== Summary ==="
                        CREATED_COUNT=0
                        for app in ui catalog assets; do
                            if argocd app get $app >/dev/null 2>&1; then
                                CREATED_COUNT=$((CREATED_COUNT + 1))
                            fi
                        done
                        
                        echo "Successfully created/found: $CREATED_COUNT out of 3 applications"
                        
                        if [ $CREATED_COUNT -lt 3 ]; then
                            echo ""
                            echo "=== Manual Creation Instructions ==="
                            echo "For any missing applications, create them manually in ArgoCD UI:"
                            echo "1. Go to: http://134.122.119.201:32129"
                            echo "2. Login with admin credentials"
                            echo "3. Click 'NEW APP' and use these settings:"
                            echo ""
                            echo "   Project: default"
                            echo "   Repository: $GITHUB_REPO"
                            echo "   Namespace: s6arserne"
                            echo ""
                            echo "   For UI: Path = helm-revive/ui, Name = ui"
                            echo "   For Catalog: Path = helm-revive/catalog, Name = catalog"
                            echo "   For Assets: Path = helm-revive/assets, Name = assets"
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline completed!"
            echo ""
            echo "✅ Check ArgoCD UI: http://134.122.119.201:32129"
            echo "📁 Target namespace: s6arserne"
            echo ""
            echo "If applications were created successfully, they should auto-sync when you push changes to the repository."
        }
        failure {
            echo "❌ Pipeline failed"
            echo "This is likely due to ArgoCD permission or project configuration issues."
            echo "Try the manual creation approach shown in the logs above."
        }
        always {
            script {
                sh 'argocd logout $ARGOCD_SERVER 2>/dev/null || true'
            }
        }
    }
}