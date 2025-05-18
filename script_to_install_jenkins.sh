#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Constants
CONTAINER_NAME="jenkins-DinD"
IMAGE_NAME="jenkins/jenkins:lts"
DOCKER_VOLUME="jenkins_home"

# Function to check if Docker is installed
check_docker_installed() {
  if ! command -v docker &>/dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
  fi
}

# Step 1: Run the Jenkins container with Docker support
run_jenkins_container() {
  echo "Starting Jenkins container..."

  docker run -d \
    --name "$CONTAINER_NAME" \
    -p 8080:8080 \
    -p 50000:50000 \
    -v "$DOCKER_VOLUME":/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$(which docker)":/usr/bin/docker:ro \
    "$IMAGE_NAME"
}

# Step 2: Add Jenkins user to Docker group inside the container
configure_jenkins_user() {
  echo "Configuring Docker access for Jenkins user..."

  docker exec -u 0 "$CONTAINER_NAME" bash -c \
    "groupadd -f docker && usermod -aG docker jenkins && chmod 666 /var/run/docker.sock"
}

# Step 3: Restart Jenkins container to apply group membership changes
restart_jenkins_container() {
  echo "Restarting Jenkins container..."
  docker restart "$CONTAINER_NAME"
}

# Step 4: Show initial admin password
show_initial_admin_password() {
  echo "Fetching initial Jenkins admin password..."
  docker exec -u 0 "$CONTAINER_NAME" cat /var/jenkins_home/secrets/initialAdminPassword
}

# Main execution
check_docker_installed
run_jenkins_container

# Wait for the container to initialize
sleep 10

configure_jenkins_user
restart_jenkins_container
sleep 5  # Give it time to restart

echo "✅ Jenkins container setup complete."
show_initial_admin_password
