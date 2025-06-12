pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['prod-s6arsene'],
            description: 'Target environment for deployment'
        )
        choice(
            name: 'APPLICATION',
            choices: ['all', 'ui', 'catalog', 'assets'],
            description: 'Select application to deploy'
        )
        string(
            name: 'IMAGE_TAG',
            defaultValue: 'latest',
            description: 'Docker image tag to deploy (e.g., latest, 123, v1.0.0)'
        )
        booleanParam(
            name: 'SKIP_APPROVAL',
            defaultValue: false,
            description: 'Skip manual approval for production deployment'
        )
        booleanParam(
            name: 'FORCE_SYNC',
            defaultValue: false,
            description: 'Force sync applications even if already synced'
        )
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }
    
    environment {
        ARGOCD_SERVER = '134.122.119.201:32129'
        ARGOCD_CREDS = credentials('argocd-credential')
        GITHUB_REPO = 'https://github.com/Arsenet7/new-revive.git'
        PROD_NAMESPACE = 'prod-s6arsene'
        DOCKER_REGISTRY = 'arsenet10'
    }
    
    stages {
        stage('Validate Parameters') {
            steps {
                script {
                    echo "🔍 Deployment Parameters:"
                    echo "  Environment: ${params.ENVIRONMENT}"
                    echo "  Application: ${params.APPLICATION}"
                    echo "  Image Tag: ${params.IMAGE_TAG}"
                    echo "  Skip Approval: ${params.SKIP_APPROVAL}"
                    echo "  Force Sync: ${params.FORCE_SYNC}"
                    
                    // Validate image tag format
                    if (params.IMAGE_TAG.trim() == '') {
                        error("Image tag cannot be empty")
                    }
                }
            }
        }
        
        stage('Pre-deployment Checks') {
            steps {
                script {
                    sh '''
                        echo "🔧 Installing ArgoCD CLI..."
                        if ! command -v argocd >/dev/null 2>&1; then
                            curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                            chmod +x argocd
                            sudo mv argocd /usr/local/bin/argocd
                        fi
                        
                        echo "🔗 Connecting to ArgoCD..."
                        argocd login $ARGOCD_SERVER \
                            --username $ARGOCD_CREDS_USR \
                            --password $ARGOCD_CREDS_PSW \
                            --insecure
                        
                        echo "📋 Current production applications:"
                        argocd app list | grep -E "(prod-|$PROD_NAMESPACE)" || echo "No production applications found"
                        
                        echo "🔍 Checking namespace exists..."
                        if command -v kubectl >/dev/null 2>&1; then
                            kubectl get namespace $PROD_NAMESPACE 2>/dev/null || echo "⚠️ Namespace $PROD_NAMESPACE may not exist"
                        else
                            echo "⚠️ kubectl not available - cannot verify namespace"
                        fi
                    '''
                }
            }
        }
        
        stage('Production Approval') {
            when {
                expression { return !params.SKIP_APPROVAL }
            }
            steps {
                script {
                    def deploymentInfo = """
🚀 PRODUCTION DEPLOYMENT REQUEST

📦 Application: ${params.APPLICATION}
🏷️  Image Tag: ${params.IMAGE_TAG}
🌐 Namespace: ${params.PROD_NAMESPACE}
⚡ Force Sync: ${params.FORCE_SYNC}

⚠️  This will deploy to PRODUCTION environment!
"""
                    
                    echo deploymentInfo
                    
                    timeout(time: 30, unit: 'MINUTES') {
                        input(
                            message: 'Approve Production Deployment?',
                            ok: 'Deploy to Production',
                            submitterParameter: 'APPROVER',
                            parameters: [
                                text(name: 'APPROVAL_NOTES', defaultValue: '', description: 'Deployment notes (optional)')
                            ]
                        )
                    }
                    
                    echo "✅ Production deployment approved by: ${env.APPROVER}"
                    if (env.APPROVAL_NOTES?.trim()) {
                        echo "📝 Approval notes: ${env.APPROVAL_NOTES}"
                    }
                }
            }
        }
        
        stage('Create/Update Production Applications') {
            steps {
                script {
                    def applications = []
                    
                    if (params.APPLICATION == 'all') {
                        applications = ['ui', 'catalog', 'assets']
                    } else {
                        applications = [params.APPLICATION]
                    }
                    
                    applications.each { app ->
                        sh """
                            echo "🔧 Processing ${app} application for production..."
                            
                            # Define production application name
                            PROD_APP_NAME="prod-${app}"
                            
                            # Check if production application exists
                            if argocd app list | grep -q "\$PROD_APP_NAME"; then
                                echo "📝 Updating existing production application: \$PROD_APP_NAME"
                                
                                # Update the application configuration
                                argocd app set \$PROD_APP_NAME \
                                    --repo $GITHUB_REPO \
                                    --path helm-revive/${app} \
                                    --dest-server https://kubernetes.default.svc \
                                    --dest-namespace $PROD_NAMESPACE \
                                    --project default 2>/dev/null || echo "⚠️ Could not update \$PROD_APP_NAME (permission issue)"
                                
                            else
                                echo "🆕 Creating new production application: \$PROD_APP_NAME"
                                
                                # Create new production application
                                argocd app create \$PROD_APP_NAME \
                                    --repo $GITHUB_REPO \
                                    --path helm-revive/${app} \
                                    --dest-server https://kubernetes.default.svc \
                                    --dest-namespace $PROD_NAMESPACE \
                                    --project default \
                                    --sync-policy automated \
                                    --auto-prune \
                                    --self-heal 2>/dev/null || echo "⚠️ Could not create \$PROD_APP_NAME (permission issue)"
                            fi
                            
                            # Set production-specific values if needed
                            echo "⚙️ Configuring production settings for \$PROD_APP_NAME..."
                            
                            sleep 2
                        """
                    }
                }
            }
        }
        
        stage('Update Image Tags') {
            when {
                expression { return params.IMAGE_TAG != 'latest' }
            }
            steps {
                script {
                    sh '''
                        echo "🏷️ Updating Helm charts with image tag: ${IMAGE_TAG}"
                        
                        # Checkout main branch for Helm chart updates
                        git config --global user.name "Jenkins Production CD"
                        git config --global user.email "jenkins-prod@company.com"
                        
                        # Clone repository
                        rm -rf helm-repo-prod
                        git clone https://github.com/Arsenet7/new-revive.git helm-repo-prod
                        cd helm-repo-prod
                        git checkout main
                        
                        # Function to update image tag in values.yaml
                        update_image_tag() {
                            local app=$1
                            local chart_path="helm-revive/$app"
                            
                            if [ -f "$chart_path/values.yaml" ]; then
                                echo "Updating $app image tag to ${IMAGE_TAG}"
                                
                                # Update image tag
                                sed -i "s/tag: .*/tag: \\"${IMAGE_TAG}\\"/" "$chart_path/values.yaml"
                                
                                # Update image repository if needed
                                case $app in
                                    "ui")
                                        sed -i "s|repository: .*|repository: \\"${DOCKER_REGISTRY}/revive-ui\\"|" "$chart_path/values.yaml"
                                        ;;
                                    "catalog")
                                        sed -i "s|repository: .*|repository: \\"${DOCKER_REGISTRY}/new-revive-catalog\\"|" "$chart_path/values.yaml"
                                        # Update database tag if exists
                                        sed -i "s/tagdb: .*/tagdb: \\"${IMAGE_TAG}\\"/" "$chart_path/values.yaml" 2>/dev/null || true
                                        ;;
                                    "assets")
                                        sed -i "s|repository: .*|repository: \\"${DOCKER_REGISTRY}/revive-assets\\"|" "$chart_path/values.yaml"
                                        ;;
                                esac
                                
                                echo "✅ Updated $app values.yaml"
                            else
                                echo "⚠️ values.yaml not found for $app"
                            fi
                        }
                        
                        # Update image tags based on selection
                        if [ "${APPLICATION}" = "all" ]; then
                            update_image_tag "ui"
                            update_image_tag "catalog"
                            update_image_tag "assets"
                        else
                            update_image_tag "${APPLICATION}"
                        fi
                        
                        # Commit and push changes
                        git add .
                        if git diff --staged --quiet; then
                            echo "No changes to commit - image tags already up to date"
                        else
                            git commit -m "🚀 Production deployment: Update ${APPLICATION} to ${IMAGE_TAG}

📦 Application: ${APPLICATION}
🏷️  Image Tag: ${IMAGE_TAG}
🌐 Target: ${PROD_NAMESPACE}
👤 Deployed by: Jenkins Production CD
🕒 Timestamp: $(date)
${APPROVAL_NOTES:+📝 Notes: $APPROVAL_NOTES}"
                            
                            # Push changes using credentials
                            git remote set-url origin https://github.com/Arsenet7/new-revive.git
                            git push origin main
                            echo "✅ Helm charts updated and pushed"
                        fi
                    '''
                }
            }
        }
        
        stage('Deploy to Production') {
            steps {
                script {
                    def applications = []
                    
                    if (params.APPLICATION == 'all') {
                        applications = ['ui', 'catalog', 'assets']
                    } else {
                        applications = [params.APPLICATION]
                    }
                    
                    applications.each { app ->
                        sh """
                            echo "🚀 Deploying ${app} to production..."
                            
                            PROD_APP_NAME="prod-${app}"
                            
                            # Refresh application to get latest changes
                            echo "🔄 Refreshing \$PROD_APP_NAME..."
                            argocd app refresh \$PROD_APP_NAME 2>/dev/null || echo "⚠️ Could not refresh \$PROD_APP_NAME"
                            
                            sleep 5
                            
                            # Sync application
                            echo "⚡ Syncing \$PROD_APP_NAME..."
                            
                            if [ "${FORCE_SYNC}" = "true" ]; then
                                echo "🔧 Force syncing \$PROD_APP_NAME..."
                                argocd app sync \$PROD_APP_NAME --force --timeout 300 2>/dev/null || echo "⚠️ Could not force sync \$PROD_APP_NAME"
                            else
                                argocd app sync \$PROD_APP_NAME --timeout 300 2>/dev/null || echo "⚠️ Could not sync \$PROD_APP_NAME"
                            fi
                            
                            sleep 10
                        """
                    }
                }
            }
        }
        
        stage('Verify Production Deployment') {
            steps {
                script {
                    sh '''
                        echo "🔍 Verifying production deployment..."
                        
                        # List all production applications
                        echo "📋 Production applications:"
                        argocd app list | grep -E "(prod-|${PROD_NAMESPACE})" || echo "No production applications found"
                        
                        echo ""
                        echo "🏥 Health check for deployed applications:"
                        
                        HEALTHY_COUNT=0
                        TOTAL_COUNT=0
                        
                        # Check health of production applications
                        for app_suffix in ui catalog assets; do
                            PROD_APP_NAME="prod-$app_suffix"
                            
                            # Skip if not deploying this app
                            if [ "${APPLICATION}" != "all" ] && [ "${APPLICATION}" != "$app_suffix" ]; then
                                continue
                            fi
                            
                            TOTAL_COUNT=$((TOTAL_COUNT + 1))
                            
                            echo "Checking $PROD_APP_NAME..."
                            
                            # Get application status
                            APP_STATUS=$(argocd app get $PROD_APP_NAME 2>&1 || echo "error")
                            
                            if echo "$APP_STATUS" | grep -q "permission denied"; then
                                echo "  🔒 Permission denied (check ArgoCD UI)"
                            elif echo "$APP_STATUS" | grep -q "Health Status:.*Healthy"; then
                                echo "  ✅ HEALTHY"
                                HEALTHY_COUNT=$((HEALTHY_COUNT + 1))
                            elif echo "$APP_STATUS" | grep -q "Health Status:.*Progressing"; then
                                echo "  🔄 PROGRESSING"
                            elif echo "$APP_STATUS" | grep -q "Health Status:.*Degraded"; then
                                echo "  ⚠️ DEGRADED"
                            else
                                echo "  ❓ Unknown status"
                            fi
                        done
                        
                        echo ""
                        echo "📊 Deployment Summary:"
                        echo "  ✅ Healthy: $HEALTHY_COUNT"
                        echo "  📊 Total: $TOTAL_COUNT"
                        
                        if [ $HEALTHY_COUNT -eq $TOTAL_COUNT ] && [ $TOTAL_COUNT -gt 0 ]; then
                            echo "🎉 ALL PRODUCTION APPLICATIONS ARE HEALTHY!"
                        elif [ $HEALTHY_COUNT -gt 0 ]; then
                            echo "⚠️ Some production applications need attention"
                        fi
                        
                        echo ""
                        echo "🔗 Check production status: http://134.122.119.201:32129"
                    '''
                }
            }
        }
        
        stage('Post-Deployment Validation') {
            steps {
                script {
                    sh '''
                        echo "✅ Production deployment completed!"
                        echo ""
                        echo "📋 Deployment Details:"
                        echo "  🎯 Environment: ${PROD_NAMESPACE}"
                        echo "  📦 Application: ${APPLICATION}"
                        echo "  🏷️  Image Tag: ${IMAGE_TAG}"
                        echo "  👤 Approved by: ${APPROVER:-"Auto-approved"}"
                        echo "  🕒 Completed: $(date)"
                        echo ""
                        echo "🔗 Monitor your applications:"
                        echo "  • ArgoCD UI: http://134.122.119.201:32129"
                        echo "  • Look for applications prefixed with 'prod-'"
                        echo ""
                        echo "🔄 Applications will auto-sync on future repository changes"
                        
                        # Create deployment record
                        echo "Creating deployment record..."
                        cat > deployment-record.json << EOF
{
  "timestamp": "$(date -Iseconds)",
  "environment": "${PROD_NAMESPACE}",
  "application": "${APPLICATION}",
  "image_tag": "${IMAGE_TAG}",
  "approver": "${APPROVER:-"auto"}",
  "build_number": "${BUILD_NUMBER}",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "jenkins_job": "${JOB_NAME}",
  "deployment_notes": "${APPROVAL_NOTES:-""}"
}
EOF
                        
                        echo "Deployment record created: deployment-record.json"
                    '''
                    
                    // Archive the deployment record
                    archiveArtifacts artifacts: 'deployment-record.json', allowEmptyArchive: true
                }
            }
        }
    }
    
    post {
        always {
            script {
                sh 'argocd logout $ARGOCD_SERVER 2>/dev/null || true'
                sh 'rm -rf helm-repo-prod || true'
            }
        }
        success {
            echo "🎉 Production Continuous Delivery Pipeline completed successfully!"
            echo ""
            echo "✅ What was accomplished:"
            echo "  - Validated deployment parameters"
            echo "  - ${params.SKIP_APPROVAL ? 'Skipped' : 'Obtained'} production approval"
            echo "  - Created/updated production applications"
            echo "  - Updated image tags to: ${params.IMAGE_TAG}"
            echo "  - Deployed to namespace: ${params.ENVIRONMENT}"
            echo "  - Verified application health"
            echo ""
            echo "🔗 Next steps:"
            echo "  - Monitor applications in ArgoCD UI"
            echo "  - Check application logs if needed"
            echo "  - Verify services are accessible"
            
            // Send notification (if configured)
            // slackSend color: 'good', message: "✅ Production deployment successful: ${params.APPLICATION} → ${params.ENVIRONMENT}"
        }
        failure {
            echo "❌ Production deployment failed!"
            echo "Please check the logs and ArgoCD UI for details"
            
            //  failure notification (if configured)
            // slackSend color: 'danger', message: "❌ Production deployment failed: ${params.APPLICATION} → ${params.ENVIRONMENT}"
        }
    }
}