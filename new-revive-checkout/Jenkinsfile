pipeline {
    agent any
    environment {
		DOCKERHUB_CREDENTIALS=credentials('del-docker-hub-auth')
	}
    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        disableConcurrentBuilds()
        timeout (time: 60, unit: 'MINUTES')
        timestamps()
      }
    stages {

        stage('test') {
            agent {
                docker { image 'node:22.4' 
                args '-u root' }
            }
            steps {
                sh'''
                cd checkout
                npm install 
                npm test --passWithNoTests || true
                '''
            }
        }

         stage('SonarQube analysis') {
            agent {
                docker {
                  image 'sonarsource/sonar-scanner-cli:5.0.1'
                }
               }
               environment {
        CI = 'true'
        scannerHome='/opt/sonar-scanner'
    }
            steps{
                withSonarQubeEnv('Sonar') {
                    sh "${scannerHome}/bin/sonar-scanner"
                }
            }
        }


    stage('Login') {

			steps {
				sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
			}
		}
        stage('build-image-api') {
            steps {
                sh '''
                cd ${WORKSPACE}/checkout
                TAG=$(git rev-parse --short=6 HEAD)
                docker build -t devopseasylearning/eric_do_it_yourself_checkout:${TAG} .
                '''
            }
        }

        stage('build-image-db') {
            steps {
                sh '''
                cd ${WORKSPACE}/checkout
                TAG=$(git rev-parse --short=6 HEAD)
                docker build -t devopseasylearning/eric_do_it_yourself_checkout_db:${TAG} . -f Dockerfile-db
                '''
            }
        }





        stage('Push-image') {
           when{ 
         expression {
           env.GIT_BRANCH == 'origin/main' }
           }
           steps {
               sh '''
               TAG=$(git rev-parse --short=6 HEAD)
           docker push devopseasylearning/eric_do_it_yourself_checkout:${TAG}
           docker push devopseasylearning/eric_do_it_yourself_checkout_db:${TAG} 
           
               '''
           }
        }


stage('trigger-deployment') {
    agent { 
        label 'deploy' 
    }
    when { 
        expression { 
            env.GIT_BRANCH == 'origin/main' 
        }
    }
    steps {
        sh '''
            TAG=$(git rev-parse --short=6 HEAD)
            rm -rf Eric-do-it-yourself-devops-automation || true
            git clone git@github.com:DEL-ORG/Eric-do-it-yourself-devops-automation.git 
            cd Eric-do-it-yourself-devops-automation/chart
            yq eval '.checkout_db.tag = "'"$TAG"'"' -i dev-values.yaml
            yq eval '.checkout.tag = "'"$TAG"'"' -i dev-values.yaml
            git config --global user.name "devopseasylearning"
            git config --global user.email info@devopseasylearning.com
            
            git add -A
            if git diff-index --quiet HEAD; then
                echo "No changes to commit"
            else
                git commit -m "updating Checkout to ${TAG}"
                git push origin main
            fi
        '''
    }
}





    }



   post {
   
   success {
      slackSend (channel: '#development-alerts', color: 'good', message: "SUCCESSFUL: Application Eric-do-it-yourself-checkout  Job '${env.JOB_NAME} [${env.TAG}]' (${env.BUILD_URL})")
    }

 
    unstable {
      slackSend (channel: '#development-alerts', color: 'warning', message: "UNSTABLE: Application Eric-do-it-yourself-checkout  Job '${env.JOB_NAME} [${env.TAG}]' (${env.BUILD_URL})")
    }

    failure {
      slackSend (channel: '#development-alerts', color: '#FF0000', message: "FAILURE: Application Eric-do-it-yourself-checkout Job '${env.JOB_NAME} [${env.TAG}]' (${env.BUILD_URL})")
    }
   
    cleanup {
      deleteDir()
    }
}





}

