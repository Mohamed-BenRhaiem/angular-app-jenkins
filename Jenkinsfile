pipeline {
    agent any

    environment {
        IMAGE_NAME  = "medbenrhaiem/aston-villa-app"
        DEPLOY_USER = "vagrant"
        DEPLOY_HOST = "192.168.56.10"
    }

    stages {

        stage('Clone Stage') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Mohamed-BenRhaiem/angular-app-jenkins.git'
            }
        }

        stage('Set Version') {
            steps {
                script {
                    env.DOCKER_TAG = sh(
                        returnStdout: true,
                        script: 'git rev-parse --short HEAD'
                    ).trim()
                    echo "DOCKER_TAG = ${env.DOCKER_TAG}"
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${env.DOCKER_TAG} ."
            }
        }

        stage('DockerHub Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                    sh "docker push ${IMAGE_NAME}:${env.DOCKER_TAG}"
                }
            }
        }

        stage('Deploy') {
            steps {
                sshagent(credentials: ['Vagrant_ssh']) {
                    sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} 'sudo docker pull ${IMAGE_NAME}:${env.DOCKER_TAG}'"
                    sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} 'sudo docker rm -f aston-villa-app || true'"
                    sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} 'sudo docker run -d --name aston-villa-app -p 80:80 ${IMAGE_NAME}:${env.DOCKER_TAG}'"
                }
            }
        }
    }
}
