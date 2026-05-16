def getVersion() {
    return sh(
        returnStdout: true,
        script: 'git rev-parse --short HEAD'
    ).trim()
}
pipeline {
    agent any
    environment {
        IMAGE_NAME = "medbenrhaiem/aston-villa-app"
        DOCKER_TAG = ""
    }
    stages {
        stage('Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/Mohamed-BenRhaiem/angular-app-jenkins.git'
            }
        }
        stage('Set Version') {
            steps {
                script {
                    env.DOCKER_TAG = getVersion()
                }
            }
        }
        stage('Docker Build') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${env.DOCKER_TAG} ."
            }
        }
        stage('Docker Login & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'''
                    sh "docker push ${IMAGE_NAME}:${env.DOCKER_TAG}"
                }
            }
        }
    }
}