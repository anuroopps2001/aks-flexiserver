#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "==== Updating system packages ===="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "==== Installing prerequisites ===="
sudo apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

echo "==== Adding Jenkins GPG key ===="
sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "==== Adding Jenkins repository ===="
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list

sudo apt-get update -y

echo "==== Installing Java 17 ===="
sudo apt-get install -y openjdk-17-jdk

echo "==== Installing Jenkins ===="
sudo apt-get install -y jenkins

echo "==== Installing Docker ===="
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo "==== Allow Jenkins to use Docker ===="
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

echo "==== Jenkins installation completed ===="
echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

