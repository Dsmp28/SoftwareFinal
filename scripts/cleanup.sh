#!/bin/bash

# Cleanup script for GKE deployment
# This script removes all resources and optionally deletes the cluster

set -e

PROJECT_ID="${GOOGLE_CLOUD_PROJECT}"
CLUSTER_NAME="microservices-cluster"
REGION="us-central1"

if [ -z "$PROJECT_ID" ]; then
    echo "Please set GOOGLE_CLOUD_PROJECT environment variable"
    exit 1
fi

echo "🧹 Cleaning up microservices deployment..."

# Remove all Kubernetes resources
echo "Removing Kubernetes resources..."
kubectl delete -f k8s/ingress.yaml --ignore-not-found=true
kubectl delete -f k8s/services/ --ignore-not-found=true
kubectl delete -f k8s/monitoring/ --ignore-not-found=true
kubectl delete -f k8s/auth/ --ignore-not-found=true
kubectl delete -f k8s/databases/ --ignore-not-found=true

# Remove persistent volumes
echo "Removing persistent volumes..."
kubectl delete pv --all --ignore-not-found=true

# Remove NGINX Ingress Controller
echo "Removing NGINX Ingress Controller..."
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml --ignore-not-found=true

echo "✅ Kubernetes resources cleaned up successfully!"

# Ask if user wants to delete the cluster
echo ""
read -p "Do you want to delete the GKE cluster '$CLUSTER_NAME'? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting GKE cluster..."
    gcloud container clusters delete $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID --quiet
    echo "✅ GKE cluster deleted successfully!"
else
    echo "GKE cluster '$CLUSTER_NAME' preserved."
    echo "To delete it later, run:"
    echo "gcloud container clusters delete $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID"
fi

echo "🎉 Cleanup completed!"