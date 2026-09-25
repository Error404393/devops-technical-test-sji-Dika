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
        stage('Test') {
            steps {
                sh '''
                    set -e
                    go test ./...
                '''
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
        stage('Deploy') {
            steps {
                sh '''
                    set -e

                    TARGET="/workspace/releases/app-1.0.0"
                    NEW="/workspace/releases/app-release"
                    BACKUP="/workspace/releases/app-rollback"

                    echo "Creating backup of current binary..."
                    cp "$TARGET" "$BACKUP"

                    rollback() {
                        trap - ERR
                        echo "Deployment failed. Rolling back..."

                        docker stop devops-app >/dev/null 2>&1 || true
                        cp "$BACKUP" "$TARGET"
                        docker start devops-app

                        echo "Rollback completed."
                    }

                    trap rollback ERR

                    echo "Stopping current application..."
                    docker stop devops-app

                    echo "Replacing application binary..."
                    cp "$NEW" "$TARGET"
                    rm -f "$NEW"

                    echo "Starting application..."
                    docker start devops-app

                    sleep 2

                    echo "Checking deployed version..."
                    RESPONSE=$(wget -qO- http://host.docker.internal:8080)

                    echo "Application response:"
                    echo "$RESPONSE"

                    echo "$RESPONSE" | grep "version=${VERSION}"

                    echo "Deployment verification successful."

                    rm -f "$BACKUP"

                    trap - ERR

                    echo "Deployment completed successfully."
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