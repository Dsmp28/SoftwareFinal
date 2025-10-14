#!/bin/bash

# GKE Deployment Script for Microservices Application
# This script builds Docker images and pushes them to Google Container Registry

set -e

# Configuration
PROJECT_ID="${GOOGLE_CLOUD_PROJECT}"
CLUSTER_NAME="microservices-cluster"
REGION="us-central1"

if [ -z "$PROJECT_ID" ]; then
    echo "Please set GOOGLE_CLOUD_PROJECT environment variable"
    exit 1
fi

echo "Building and pushing Docker images to gcr.io/$PROJECT_ID..."

# Array of services to build
services=(
    "api-gateway"
    "product-service"
    "order-service"
    "inventory-service"
    "notification-service"
    "microservices-shop-frontend"
)

# Build and push each service
for service in "${services[@]}"; do
    echo "Building $service..."
    
    if [ "$service" = "microservices-shop-frontend" ]; then
        # Handle frontend service
        cd microservices-shop-frontend
        docker build -t gcr.io/$PROJECT_ID/frontend:latest .
        docker push gcr.io/$PROJECT_ID/frontend:latest
        cd ..
    else
        # Handle Java Spring Boot services
        cd $service
        docker build -t gcr.io/$PROJECT_ID/$service:latest .
        docker push gcr.io/$PROJECT_ID/$service:latest
        cd ..
    fi
    
    echo "✅ $service built and pushed successfully"
done

echo "🎉 All Docker images built and pushed successfully!"
echo "📝 Next steps:"
echo "   1. Run ./scripts/setup-gke.sh to create the GKE cluster"
echo "   2. Run ./scripts/deploy.sh to deploy the application"