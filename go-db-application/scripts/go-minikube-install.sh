#!/bin/bash

echo "===== Installation started ====="

echo "===== minikube installation started ===="
sudo apt update
sudo apt install -y curl wget apt-transport-https

echo "==== minikube package started downloading ===="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

echo "==== minikube version ===="
minikube version

echo "==== minikube installation completed ===="


echo "=== kubectl package download started ===="
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
echo "=== kubectl donwload completed"

echo "=== start minikube ===="
minikube start --driver=docker
echo "=== minikube started successfully...!! ===="
