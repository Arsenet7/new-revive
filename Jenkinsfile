pipeline {
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
        SONAR_SCANNER_VERSION = '5.0.1.3006'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-ars-id')
        DOCKER_IMAGE_CATALOG = 'arsenet10/new-revive-catalog'
        DOCKER_IMAGE_DB = 'arsenet10/new-revive-catalog-db'
        BUILD_VERSION = "${env.BUILD_NUMBER}"
        HELM_CHART_PATH = 'helm-revive/catalog'
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: 'catalog']], 
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

        stage('Build and Test') {
            steps {
                // Run Docker directly as a command for simplicity
                sh '''
                    # Run a temporary Go container to build and test the code
                    docker run --rm \
                        -v "${WORKSPACE}:/workspace" \
                        -w "/workspace/new-revive-catalog/catalog" \
                        golang:1.21 \
                        bash -c "set -xe && \
                            go mod download && \
                            go build -buildvcs=false -v . && \
                            (ls *_test.go >/dev/null 2>&1 && go test -buildvcs=false -v . || echo 'No tests to run')"
                '''
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression { return !params.SKIP_SONAR }
            }
            steps {
                script {
                    withSonarQubeEnv('sonar') {
                        withCredentials([string(credentialsId: 'sonarqube-jenkins-id', variable: 'SONAR_TOKEN')]) {
                            sh '''
                                cd new-revive-catalog/catalog
                                ${SCANNER_HOME}/bin/sonar-scanner \
                                    -Dsonar.projectKey=new-revive-catalog \
                                    -Dsonar.projectName="New Revive Catalog" \
                                    -Dsonar.sources=. \
                                    -Dsonar.exclusions="**/*_test.go,**/vendor/**" \
                                    -Dsonar.go.coverage.reportPaths=coverage.out \
                                    -Dsonar.login=${SONAR_TOKEN} 
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
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build and Push Docker Images') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-ars-id') {
                        // Build and push catalog image
                        dir('new-revive-catalog/catalog') {
                            def catalogImage = docker.build("${DOCKER_IMAGE_CATALOG}:${BUILD_VERSION}", "-f Dockerfile .")
                            catalogImage.push()
                            catalogImage.push('latest')
                        }
                        
                        // Build and push db image
                        dir('new-revive-catalog/catalog') {
                            def dbImage = docker.build("${DOCKER_IMAGE_DB}:${BUILD_VERSION}", "-f Dockerfile-db .")
                            dbImage.push()
                            dbImage.push('latest')
                        }
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
                            # Update catalog image tag
                            sed -i '/catalog:/,/tag:/ s/tag: .*/tag: "${BUILD_VERSION}"/' ${HELM_CHART_PATH}/values.yaml || true
                            
                            # Update database image tag (using tagdb key)
                            sed -i '/database:/,/tagdb:/ s/tagdb: .*/tagdb: "${BUILD_VERSION}"/' ${HELM_CHART_PATH}/values.yaml || true
                            sed -i 's/tagdb: .*/tagdb: "${BUILD_VERSION}"/' ${HELM_CHART_PATH}/values.yaml || true
                            
                            # Update catalog tag (general fallback)
                            sed -i 's/tag: .*/tag: "${BUILD_VERSION}"/' ${HELM_CHART_PATH}/values.yaml
                            
                            echo "Updated Helm chart values.yaml with image tags: ${BUILD_VERSION}"
                            echo "=== Updated values.yaml content ==="
                            cat ${HELM_CHART_PATH}/values.yaml | grep -A2 -B2 -E "(tag:|tagdb:)"
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
                                        git commit -m "Update catalog and database image tags to ${BUILD_VERSION} - Build ${BUILD_NUMBER}

- Catalog image: ${DOCKER_IMAGE_CATALOG}:${BUILD_VERSION}
- Database image: ${DOCKER_IMAGE_DB}:${BUILD_VERSION}

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
    }

    post {
        success {
            echo 'Build, tests, SonarQube analysis, Docker images push, and Helm chart update completed successfully!'
        }
        failure {
            echo 'Build, tests, SonarQube analysis, Docker images push, or Helm chart update failed!'
        }
        always {
            // Clean up local images
            script {
                sh """
                    docker rmi ${DOCKER_IMAGE_CATALOG}:${BUILD_VERSION} || true
                    docker rmi ${DOCKER_IMAGE_CATALOG}:latest || true
                    docker rmi ${DOCKER_IMAGE_DB}:${BUILD_VERSION} || true
                    docker rmi ${DOCKER_IMAGE_DB}:latest || true
                """
            }
            cleanWs()
        }
    }
}