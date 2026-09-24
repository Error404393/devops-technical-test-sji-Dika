pipeline {
    agent any

    environment{
        DOCKER_IMAGE = 'dikta1803/devops-technical-test-sji'
        DOCKER_CREDENTIALS = 'dockerhub-credentials'
    }
    
    stages{
        
        stage('Checkout'){
            steps {
                checkout scm
            }
        }
        stage('Test'){
            steps{
                sh 'go test ./...'
            }
        }
        stage('Prepare Version'){
            steps{
                script{
                    env.VERSION = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    
                    echo "Build version: ${env.VERSION}"
                }
            }
        }
        stage('Build Binary'){
            steps{
                sh '''
                    CGO_ENABLED=0 \
                    GOOS=linux \
                    GOARCH=amd64 \
                    go build \
                    -ldflags="-X main.version=${VERSION}" \
                    -o app-release .
                '''
            }
        }
        stage ('Build Docker Image'){
            steps{
                sh '''
                    docker build \
                    --build-arg VERSION=${VERSION} \
                    -t ${DOCKER_IMAGE}:${VERSION} .
                '''
            }
        }
        stage('Push Docker Image'){
            steps{
                withCredentials([
                    usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_TOKEN'
                    )
                ]){
                    sh '''
                        set +x
                        echo "$DOCKER_TOKEN" | docker login \
                            -u "$DOCKER_USER" \
                            --password-stdin
                        docker push ${DOCKER_IMAGE}:${VERSION}

                        docker logout
                    '''
                }
            }
        }
        stage('Deploy'){
            steps{
                sh '''
                    docker cp app-release devops-app:/tmp/app-release
                    docker stop devops-app
                    docker exec devops-app sh -c 'cat /tmp/app-release > /app/app && chmod +x /app/app'
                    docker exec devops-app rm -f /tmp/app-release
                    docker start devops-app 
                '''
            }
        }
        stage('Verify'){
            steps{
                sh '''
                    sleep 2
                    RESPONSE=$(wget -qO- http://host.docker.internal:8080)

                    echo "Application response:"
                    echo "$RESPONSE"

                    echo "$RESPONSE" | grep "version=${VERSION}"
                '''
            }
        }
    }
    post{
        success{
            echo 'CI/CD pipeline completed successfully'
        }

        failure{
            echo 'CI/CD pipeline failed'
        }
    }
}