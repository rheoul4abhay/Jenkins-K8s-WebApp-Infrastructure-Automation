FROM ubuntu:22.04

USER root

RUN apt-get update && apt-get install -y \
    openssh-server sudo curl ca-certificates gnupg lsb-release \
    software-properties-common wget unzip git openjdk-17-jre-headless \
    docker.io

ARG DOCKER_GID=998
RUN groupmod -g ${DOCKER_GID} docker && \
    useradd -m -s /bin/bash jenkins && \
    usermod -aG docker jenkins && \
    echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir /home/jenkins/.ssh

COPY id_rsa.pub /home/jenkins/.ssh/authorized_keys
# SSH daemon
RUN mkdir -p /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config || true
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config || true

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]