#!/bin/bash

# GKE Cluster Setup Script
# This script creates a GKE cluster with necessary configurations

set -e

# Configuration
PROJECT_ID="strange-math-475005-p1"
CLUSTER_NAME="software-cluster"
ZONE="us-east1-b"
NODE_POOL_NAME="main-pool"
MACHINE_TYPE="e2-standard-2"
NUM_NODES="3"
MIN_NODES="1"
MAX_NODES="5"

if [ -z "$PROJECT_ID" ]; then
    echo "Please set GOOGLE_CLOUD_PROJECT environment variable"
    exit 1
fi

echo "Creating GKE cluster: $CLUSTER_NAME in project: $PROJECT_ID"

# Enable required APIs
echo "Enabling required Google Cloud APIs..."
gcloud services enable container.googleapis.com --project=$PROJECT_ID
gcloud services enable containerregistry.googleapis.com --project=$PROJECT_ID
gcloud services enable cloudbuild.googleapis.com --project=$PROJECT_ID

# Create GKE cluster
echo "Creating GKE cluster..."
gcloud container clusters create software-cluster \
    --project=strange-math-475005-p1 \
    --zone=us-east1-b \
    --machine-type=e2-standard-2 \
    --num-nodes=3 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=5 \
    --enable-autorepair \
    --enable-autoupgrade \
    --disk-size=50GB \
    --disk-type=pd-ssd \
    --enable-ip-alias \
    --network=default \
    --subnetwork=default \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing \
    --workload-pool=strange-math-475005-p1.svc.id.goog

# Get cluster credentials
echo "Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Wait for NGINX Ingress Controller to be ready
echo "Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

# Create namespace for monitoring (if needed)
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

echo " GKE cluster created successfully!"
echo "=Ý Cluster details:"
echo "   Name: $CLUSTER_NAME"
echo "   Zone: $ZONE"
echo "   Project: $PROJECT_ID"
echo "   Nodes: $NUM_NODES (autoscaling: $MIN_NODES-$MAX_NODES)"
echo ""
echo "= Connect to your cluster:"
echo "   gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID"
echo ""
echo "=Ý Next steps:"
echo "   1. Run ./scripts/build-images.sh to build and push Docker images"
echo "   2. Run ./scripts/deploy.sh to deploy the application"