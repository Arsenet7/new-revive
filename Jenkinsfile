pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Checkout code from GitHub repository
                git branch: 'main', url: 'git@github.com:your-username/your-repository.git'
            }
        }

        stage('Unit Test') {
            steps {
                echo 'Running Unit Tests...'
                // Add your command to run unit tests
                sh './run-tests.sh'  // Example: Running a test script
            }
        }
    }
}
