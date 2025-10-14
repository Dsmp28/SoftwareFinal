#!/bin/bash

# Update Kubernetes manifests with actual project ID
# Usage: ./update-manifests.sh [PROJECT_ID]

set -e

PROJECT_ID=${1:-$GOOGLE_CLOUD_PROJECT}

if [ -z "$PROJECT_ID" ]; then
    echo "Usage: $0 <PROJECT_ID>"
    echo "Or set GOOGLE_CLOUD_PROJECT environment variable"
    exit 1
fi

echo "Updating Kubernetes manifests with PROJECT_ID: $PROJECT_ID"

# Find all YAML files in k8s directory and replace PROJECT_ID placeholder
find k8s -name "*.yaml" -type f -exec sed -i.bak "s/PROJECT_ID/$PROJECT_ID/g" {} \;

# Remove backup files
find k8s -name "*.bak" -type f -delete

echo "✓ All manifests updated with PROJECT_ID: $PROJECT_ID"
echo "Ready to deploy to GKE!"