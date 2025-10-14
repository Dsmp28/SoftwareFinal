#!/bin/bash

# Environment setup for GKE deployment
export GOOGLE_CLOUD_PROJECT="strange-math-475005-p1"
export CLUSTER_NAME="software-cluster"
export REGION="us-east1"

echo "Environment configured:"
echo "Project ID: $GOOGLE_CLOUD_PROJECT"
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $REGION"