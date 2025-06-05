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
        SONAR_PROJECT_KEY = 'new-revive-catalog'
        SONAR_PROJECT_NAME = 'New Revive Catalog'
        SCANNER_HOME = tool 'sonar'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-ars-id')
        DOCKER_IMAGE_CATALOG = 'arsenet10/new-revive-catalog'
        DOCKER_IMAGE_DB = 'arsenet10/new-revive-catalog-db'
        IMAGE_TAG = "${BUILD_NUMBER}"
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

        stage('Build with Go') {
            agent {
                docker {
                    image 'golang:1.21'
                    reuseNode true
                }
            }
            steps {
                sh 'go version'
                sh '''
                    cd new-revive-catalog/catalog
                    go mod download
                    go build -buildvcs=false -v .
                '''
            }
        }

        stage('Test with Coverage') {
            agent {
                docker {
                    image 'golang:1.21'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    cd new-revive-catalog/catalog
                    if ls *_test.go >/dev/null 2>&1; then
                        go test -buildvcs=false -v -coverprofile=coverage.out -covermode=atomic ./...
                        go tool cover -html=coverage.out -o coverage.html
                        echo "Tests completed with coverage report generated"
                    else
                        echo "No tests found to run"
                        touch coverage.out
                    fi
                '''
            }
            post {
                always {
                    script {
                        // Publish coverage report if it exists
                        if (fileExists('new-revive-catalog/catalog/coverage.html')) {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'new-revive-catalog/catalog',
                                reportFiles: 'coverage.html',
                                reportName: 'Go Coverage Report'
                            ])
                        }
                    }
                }
            }
        }

        stage('Static Code Analysis') {
            parallel {
                stage('Go Vet') {
                    agent {
                        docker {
                            image 'golang:1.21'
                            reuseNode true
                        }
                    }
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            sh '''
                                cd new-revive-catalog/catalog
                                go vet ./... || true
                            '''
                        }
                    }
                }
                stage('Go Fmt') {
                    agent {
                        docker {
                            image 'golang:1.21'
                            reuseNode true
                        }
                    }
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            sh '''
                                cd new-revive-catalog/catalog
                                unformatted=$(gofmt -l .)
                                if [ -n "$unformatted" ]; then
                                    echo "Go files must be formatted with gofmt. Please run:"
                                    for file in $unformatted; do
                                        echo "  gofmt -w $file"
                                    done
                                    exit 1
                                fi
                            '''
                        }
                    }
                }
                stage('Go Lint') {
                    agent {
                        docker {
                            image 'golangci/golangci-lint:latest'
                            reuseNode true
                        }
                    }
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            sh '''
                                cd new-revive-catalog/catalog
                                golangci-lint run --timeout=10m || true
                            '''
                        }
                    }
                }
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
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                    -Dsonar.projectName="${SONAR_PROJECT_NAME}" \
                                    -Dsonar.projectVersion=${BUILD_NUMBER} \
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
                            def catalogImage = docker.build("${DOCKER_IMAGE_CATALOG}:${IMAGE_TAG}", "-f Dockerfile .")
                            catalogImage.push()
                            catalogImage.push('latest')
                        }
                        
                        // Build and push db image
                        dir('new-revive-catalog/catalog') {
                            def dbImage = docker.build("${DOCKER_IMAGE_DB}:${IMAGE_TAG}", "-f Dockerfile-db .")
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
                            sed -i 's/catalog:.*tag: .*/catalog:\\n    image:\\n      tag: "${IMAGE_TAG}"/' ${HELM_CHART_PATH}/values.yaml || true
                            sed -i '/catalog:/,/tag:/ s/tag: .*/tag: "${IMAGE_TAG}"/' ${HELM_CHART_PATH}/values.yaml || true
                            
                            # Update database image tag  
                            sed -i 's/database:.*tag: .*/database:\\n    image:\\n      tag: "${IMAGE_TAG}"/' ${HELM_CHART_PATH}/values.yaml || true
                            sed -i '/database:/,/tag:/ s/tag: .*/tag: "${IMAGE_TAG}"/' ${HELM_CHART_PATH}/values.yaml || true
                            
                            # Alternative: Simple tag replacement (if all services use same tag)
                            sed -i 's/tag: .*/tag: "${IMAGE_TAG}"/' ${HELM_CHART_PATH}/values.yaml
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
                                        git commit -m "Update catalog image tags to ${IMAGE_TAG} - Build ${BUILD_NUMBER}"
                                        echo "Pushing changes to repository..."
                                        git push origin main
                                        echo "Successfully updated Helm chart with image tag ${IMAGE_TAG}"
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
                    docker rmi ${DOCKER_IMAGE_CATALOG}:${IMAGE_TAG} || true
                    docker rmi ${DOCKER_IMAGE_CATALOG}:latest || true
                    docker rmi ${DOCKER_IMAGE_DB}:${IMAGE_TAG} || true
                    docker rmi ${DOCKER_IMAGE_DB}:latest || true
                """
            }
            cleanWs()
        }
    }
}