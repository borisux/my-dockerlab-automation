#!/bin/bash

# Variables
IMAGE_NAME="ansible_node"
CONTAINERS=("node1" "node2" "node3")
INVENTORY_FILE="hosts.ini"
PLAYBOOK_FILE="playbook.yml"
DOCKERFILE_PATH="."

# Build the Docker Image
docker build -t $IMAGE_NAME $DOCKERFILE_PATH

# Function to check if a container exists
container_exists() {
    docker ps -a --filter "name=$1" | grep -w $1 > /dev/null 2>&1
    return $?
}

# Launch Docker Containers
for container in "${CONTAINERS[@]}"; do
    if container_exists $container; then
        echo "Container $container already exists. Starting it..."
        docker start $container
    else
        echo "Container $container does not exist. Creating and starting it..."
        port=$((2221 + ${container#"node"}))
        docker run -d --name $container -p $port:22 $IMAGE_NAME
    fi
done

# Give the containers a few seconds to start SSH
echo "Waiting for containers to initialize..."
sleep 10

# Execute Ansible Playbook
ansible-playbook -i $INVENTORY_FILE $PLAYBOOK_FILE

echo "Playbook execution finished."
