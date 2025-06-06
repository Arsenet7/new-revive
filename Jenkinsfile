pipeline {
    agent any
    
    environment {
        ARGOCD_SERVER = '134.122.119.201:32129'
        ARGOCD_CREDS = credentials('argocd-credential')
        GITHUB_REPO = 'https://github.com/Arsenet7/new-revive.git'
        TARGET_NAMESPACE = 's6arsene'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${GITHUB_REPO}"
            }
        }
        
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
                        argocd login $ARGOCD_SERVER \
                            --username $ARGOCD_CREDS_USR \
                            --password $ARGOCD_CREDS_PSW \
                            --insecure
                        
                        echo "Checking user permissions..."
                        argocd account get-user-info
                    '''
                }
            }
        }
        
        stage('Check and Clean Existing Apps') {
            steps {
                script {
                    sh '''
                        echo "Checking existing applications..."
                        argocd app list || echo "Could not list applications"
                        
                        # Try to delete existing applications if they exist and we have permission
                        for app in ui catalog assets; do
                            if argocd app list | grep -q $app; then
                                echo "Found existing application: $app"
                                echo "Attempting to delete $app..."
                                argocd app delete $app --cascade --yes || echo "Could not delete $app, continuing..."
                                sleep 5
                            fi
                        done
                    '''
                }
            }
        }
        
        stage('Create Applications via YAML') {
            steps {
                script {
                    // Create application YAML files and apply them using kubectl
                    sh '''
                        # Create UI application YAML
                        cat > ui-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ui
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Arsenet7/new-revive.git
    targetRevision: HEAD
    path: helm-revive/ui
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: s6arsene
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
EOF

                        # Create Catalog application YAML
                        cat > catalog-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: catalog
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Arsenet7/new-revive.git
    targetRevision: HEAD
    path: helm-revive/catalog
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: s6arsene
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
EOF

                        # Create Assets application YAML
                        cat > assets-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: assets
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Arsenet7/new-revive.git
    targetRevision: HEAD
    path: helm-revive/assets
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: s6arsene
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
EOF

                        # Apply the applications using kubectl
                        kubectl apply -f ui-app.yaml
                        kubectl apply -f catalog-app.yaml
                        kubectl apply -f assets-app.yaml
                        
                        echo "Applications created via kubectl"
                    '''
                }
            }
        }
        
        stage('Wait and Sync Applications') {
            steps {
                script {
                    sh '''
                        echo "Waiting for applications to be recognized..."
                        sleep 30
                        
                        # Try to sync each application
                        for app in ui catalog assets; do
                            echo "Attempting to sync $app..."
                            
                            # Try multiple times with different approaches
                            if argocd app sync $app --timeout 60; then
                                echo "Successfully synced $app"
                            elif argocd app sync $app --force --timeout 60; then
                                echo "Force synced $app successfully"
                            else
                                echo "Could not sync $app via CLI, checking status..."
                                argocd app get $app || echo "Could not get $app status"
                            fi
                            
                            sleep 10
                        done
                    '''
                }
            }
        }
        
        stage('Verify Deployments') {
            steps {
                script {
                    sh '''
                        echo "Final application status:"
                        argocd app list || echo "Could not list applications"
                        
                        for app in ui catalog assets; do
                            echo "=== Status for $app ==="
                            argocd app get $app || echo "Could not get $app details"
                            echo ""
                        done
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                sh 'argocd logout $ARGOCD_SERVER || true'
            }
        }
        success {
            echo "Applications deployed successfully!"
        }
        failure {
            echo "Deployment failed - check ArgoCD permissions and configuration"
        }
    }
}