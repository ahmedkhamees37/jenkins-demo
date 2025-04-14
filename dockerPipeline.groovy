def call(Map config = [:]) {
    pipeline {
        agent {
            label config.agent ?: 'docker-agent'
        }

        environment {
            IMAGE_NAME = config.imageName ?: 'my-image'
            IMAGE_TAG  = config.imageTag ?: 'latest'
            REGISTRY   = config.registry ?: 'docker.io/your-dockerhub-username'
            DOCKER_CREDENTIALS_ID = config.credentialsId ?: 'docker-hub-creds'
        }

        stages {
            stage('Clone Repo') {
                steps {
                    git url: config.repoUrl, branch: config.branch ?: 'main'
                }
            }

            stage('Build Docker Image') {
                steps {
                    script {
                        sh "docker build -t $REGISTRY/$IMAGE_NAME:$IMAGE_TAG ."
                    }
                }
            }

            stage('Push Docker Image') {
                steps {
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh """
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $REGISTRY
                            docker push $REGISTRY/$IMAGE_NAME:$IMAGE_TAG
                        """
                    }
                }
            }
        }
    }
}
