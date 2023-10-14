FROM ubuntu:20.04

# Avoids prompting for timezone
ENV DEBIAN_FRONTEND=noninteractive

# Install SSH server and Python (for Ansible)
RUN apt-get update && apt-get install -y openssh-server python3 sudo

RUN mkdir -p /run/sshd
RUN useradd -m ansible && echo "ansible:ansible" | chpasswd && adduser ansible sudo
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# Start SSH
CMD ["/usr/sbin/sshd", "-D"]