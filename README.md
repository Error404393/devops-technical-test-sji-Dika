# DevOps Technical Test - Raden Dika Natakusumah
## PT Simple Journey Indonesia

## Environment
    - OS: Windows
    - Golang:1.24.0
    - Docker: 29.8.0
    - Git: 2.46.2
---

# PART 1 - BUILD

### 1. Multi-stage Dockerfile
The application is built using a multi-stage Dockerfile consisting of two stages:

- **Build stage**: uses 'golang:1.24-alpine' to compile the Go application into a statically linked Linux binary.
- **Runtime stage**: uses 'alpine:3.22' as the minimal runtime environment and copies only the compiled binary from the build stage.

The build stage uses 'CGO_ENABLED=0' to produce a statically linked binary without dependencies on shared libraries from the builder OS.

### Why i use alpine image?
Alpine was selected as the base image because its a ligthweight Linux distribution suitable for running the compiled Go binary. It allows the final image to contain only the minimal runtime environment and the application binary, instead of including the Go toolchain and another build dependencies.

This approach helps reduce the final image size while keeping the container environment sufficient to run application.

### 2. Build Command

docker build --build-arg VERSION=1.0.0 -t devops-app:1.0.0 .

### 3. Final Image Size
devops-app:1.0.0
Disk Usage: 16.4MB

The final image have 16.4 MB because the multi-stage build excludes the Go toolchain, source code, and build dependencies from runtime image. The final stage contains only alpine and the compiled application binary.
check for the proof in screenshots/02-docker-image-size.png

# PART 2 - DEPLOY

### 4. Run Container
The docker image was deployed as a container with port '8080' exposed to the host and an automatic restart policy.

docker run -d --name devops-app -p 8080:8080 --restart unless-stopped devops-app:1.0.0

the initial deployment was verified with: curl http://localhost:8080 with output : Hello, DevOps! version=1.0.0 (Proof in screenshot 03-deploy-container-v1.png)

### 5. Binary Replacement Strategy
For the binary replacement scenario, the bind mount approach was selected. The application binary is stored separetly from Docker Image and Mounted into the container, allwing the binary to be replaced without rebuilding the Docker IMage.

First, the initial is 1.0.0 binary was built on the host: 

set GOOS=linux&&set GOARCH=amd64&&set CGO_ENABLED=0&&go build -ldflags="-X main.version=1.0.0" -o releases\app-1.0.0 .

and the container was then run with the binary mounted from the host:

docker run -d --name devops-app -p 8080:8080 --restart unless-stopped -v "%cd%\releases\app-1.0.0:/app/app" devops-app:1.0.0

For the hotfix, a new 1.0.1 binary was built without rebuilding the docker image and container:

set GOOS=linux&&set GOARCH=amd64&&set CGO_ENABLED=0&&go build -ldflags="-X main.version=1.0.1" -o releases\app-1.0.1 .

The mounted binary was then replaced: copy /Y releases\app-1.0.1 releases\app-1.0.0
the existing container was restarted: docker restart devops-app

### 6. Binary Swap Verification

Before the binary swap: (Proof in 04-deploy-bind-mount-v1.png)
Hello, DevOps! version=1.0.0

and after replacing the binary and restarting the existing container: (Proof in 05-hotfix-after-v1.0.1.png)
Hello, DevOps! version=1.0.1

Hotfix Approach Explanation:
The bind mount approach was chosen to separate the application binary from the Docker Image. This allows a new binary to be built and replaced independently without rebuilding the Docker Image. Restarting the existing container starts teh updated binary while keeping the same container and image. This approach is suitable for a small production hotfix because it reduces the deployment steps and avoids a full image rebuild.