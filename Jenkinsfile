String deduceDockerTag() {
    String dockerTag = env.BRANCH_NAME
    if (dockerTag.equals("main") || dockerTag.equals("master")) {
        echo "Building the 'main' branch so we'll publish a Docker tag starting with 'latest'"
        dockerTag = "latest"
    } else {
        dockerTag += "-${env.BUILD_NUMBER}"
        echo "Building a branch other than 'main' so will publish a Docker tag starting with '$dockerTag', not 'latest'"
    }
    return dockerTag
}

pipeline {
    agent {
        label 'docker'  // Agent with Docker capability
    }
    
    environment {
        GCP_PROJECT_ID = 'teralivekubernetes'
        GCP_REGION = 'us-east1'
        GAR_BASE_URL = "${GCP_REGION}-docker.pkg.dev"
        GAR_REPOSITORY = "logistics"  // Jenkins agents registry
        DOCKER_TAG = deduceDockerTag()
        IMAGE_NAME = "jenkins-python-ai-agent"
        FULL_IMAGE_NAME = "${GAR_BASE_URL}/${GCP_PROJECT_ID}/${GAR_REPOSITORY}/${IMAGE_NAME}:${DOCKER_TAG}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker') {
            steps {
                script {
                    // Build from jenkins-agent directory (self-contained)
                    dir('jenkins-agent') {
                        sh """
                            docker build -f Dockerfile -t ${FULL_IMAGE_NAME} .
                        """
                    }
                }
            }
        }
        
        stage('Push Docker') {
            steps {
                script {
                    // Authenticate with GAR using the service account key then push
                    withCredentials([file(credentialsId: 'jenkins-gar-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh """
                            cat \${GOOGLE_APPLICATION_CREDENTIALS} | docker login -u _json_key --password-stdin https://${GAR_BASE_URL}
                            docker push ${FULL_IMAGE_NAME}
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "Jenkins agent image built and pushed successfully!"
            echo "Image: ${FULL_IMAGE_NAME}"
            echo "Update Jenkins pod template to use this image."
        }
        failure {
            echo "Build failed. Check logs above for details."
        }
    }
}
