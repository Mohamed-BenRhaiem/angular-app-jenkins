def getVersion() {
    def version = sh(
        returnStdout: true,
        script: 'git rev-parse --short HEAD'
    ).trim()

    return version
}

pipeline {
    agent any

    stages {

        stage('Clone Stage') {
            steps {
                git 'https://gitlab.com/jmlhmd/datacamp_docker_angular.git'
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
                sh "docker build -t jmlhmd/image_name:${DOCKER_TAG} ."
            }
        }

        stage('DockerHub Push') {
            steps {

                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'

                    sh "docker push jmlhmd/aston-villa-app:${DOCKER_TAG}"
                }
            }
        }

    }
}