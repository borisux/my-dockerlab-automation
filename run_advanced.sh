#!/bin/bash

# Variables
IMAGE_NAME="ansible_node"
CONTAINERS=($(seq -f "node%g" 1 3))
#CONTAINERS=("node1" "node2" "node3")
INVENTORY_FILE="hosts.ini"
PLAYBOOK_FILE="playbook.yml"
DOCKERFILE_PATH="."

# Function to check if a container exists
container_exists() {
    docker ps -a --filter "name=$1" | grep -w $1 > /dev/null 2>&1
    return $?
}

# Function to stop and remove containers
stop_and_remove_containers() {
    for container in "${CONTAINERS[@]}"; do
        if container_exists $container; then
            echo "Stopping and removing container $container..."
            docker stop $container
            docker rm $container
        else
            echo "Container $container does not exist."
        fi
    done
}

create_inventory_file() {
    echo "[nodes]" > $INVENTORY_FILE
    for container in "${CONTAINERS[@]}"; do
        port=$((2220 + ${container#"node"}))
        echo "$container ansible_host=localhost ansible_port=$port ansible_user=ansible ansible_ssh_pass=ansible">> $INVENTORY_FILE
    done
    echo "#DONE" >> $INVENTORY_FILE
}


# Main logic
while true; do
    clear
    echo "#################################"
    echo "# Docker-Ansible Management Menu"
    echo "#################################"
    echo "# 1. Create/Start containers"
    echo "# 2. STOP and remove ALL  the containers"
    echo "# 3. Execute Ansible playbook on containers"
    echo "# 4. Display running containers"
    echo "# 5. Exit"
    echo "#################################"
    read -p "Enter your choice (1/2/3/4/5): " choice

    case $choice in
        1)
            # Build the Docker Image
            docker build -t $IMAGE_NAME $DOCKERFILE_PATH

            # Launch Docker Containers
            for container in "${CONTAINERS[@]}"; do
                if container_exists $container; then
                    echo "Container $container already exists. Starting it..."
                    docker start $container
                else
                    echo "Container $container does not exist. Creating and starting it..."
                    port=$((2220 + ${container#"node"}))
                    docker run -d --name $container -p $port:22 $IMAGE_NAME
                fi
            done
            
            #Create a host.ini file
            create_inventory_file

            # Give the containers a few seconds to start SSH
            echo "Waiting 3 sec for containers to initialize..."
            sleep 3
            read -p "Press any key to continue..." ;;
        
        2)
            stop_and_remove_containers
            read -p "Press any key to continue..." ;;
        
        3)
            # Execute Ansible Playbook
            ansible-playbook -i $INVENTORY_FILE $PLAYBOOK_FILE -K -f 3
            read -p "Press any key to continue..." ;;
        
       4)
            echo "Displaying running containers..."
            docker ps --filter "ancestor=$IMAGE_NAME"
            read -p "Press any key to continue..." ;;        
        
        5)
            echo "Exiting..."
            exit 0 ;;
        
        *)
            echo "Invalid choice!"
            read -p "Press any key to continue..." ;;
    esac
done
