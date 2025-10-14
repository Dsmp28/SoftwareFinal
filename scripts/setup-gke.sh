#!/bin/bash

# GKE Cluster Setup Script
# This script creates a GKE cluster with necessary configurations

set -e

# Configuration
PROJECT_ID="${GOOGLE_CLOUD_PROJECT}"
CLUSTER_NAME="microservices-cluster"
REGION="us-central1"
NODE_POOL_NAME="main-pool"
MACHINE_TYPE="e2-standard-4"
NUM_NODES="3"
MIN_NODES="1"
MAX_NODES="10"

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
gcloud container clusters create $CLUSTER_NAME \
    --project=$PROJECT_ID \
    --region=$REGION \
    --machine-type=$MACHINE_TYPE \
    --num-nodes=$NUM_NODES \
    --enable-autoscaling \
    --min-nodes=$MIN_NODES \
    --max-nodes=$MAX_NODES \
    --enable-autorepair \
    --enable-autoupgrade \
    --disk-size=50GB \
    --disk-type=pd-ssd \
    --enable-ip-alias \
    --network=default \
    --subnetwork=default \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing,NetworkPolicy \
    --enable-network-policy \
    --workload-pool=$PROJECT_ID.svc.id.goog

# Get cluster credentials
echo "Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID

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

echo "✅ GKE cluster created successfully!"
echo "📝 Cluster details:"
echo "   Name: $CLUSTER_NAME"
echo "   Region: $REGION"
echo "   Project: $PROJECT_ID"
echo "   Nodes: $NUM_NODES (autoscaling: $MIN_NODES-$MAX_NODES)"
echo ""
echo "🔗 Connect to your cluster:"
echo "   gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID"
echo ""
echo "📝 Next steps:"
echo "   1. Run ./scripts/build-images.sh to build and push Docker images"
echo "   2. Run ./scripts/deploy.sh to deploy the application"