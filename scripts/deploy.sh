#!/bin/bash

# Deployment Script for Microservices Application on GKE
# This script deploys all Kubernetes manifests in the correct order

set -e

PROJECT_ID="strange-math-475005-p1"

if [ -z "$PROJECT_ID" ]; then
    echo "Please set PROJECT_ID variable or GOOGLE_CLOUD_PROJECT environment variable"
    exit 1
fi

echo "Deploying microservices application to GKE..."

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment_name=$1
    local namespace=${2:-default}
    echo "Waiting for deployment $deployment_name to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment_name -n $namespace 2>/dev/null || echo "Deployment $deployment_name not found or not ready yet"
}

# Function to wait for pods to be ready
wait_for_pods() {
    local app_label=$1
    local namespace=${2:-default}
    echo "Waiting for pods with label app=$app_label to be ready..."
    kubectl wait --for=condition=ready --timeout=300s pod -l app=$app_label -n $namespace 2>/dev/null || echo "Pods with label $app_label not found or not ready yet"
}

# Update PROJECT_ID in Kubernetes manifests
echo "Updating PROJECT_ID in Kubernetes manifests..."
find k8s/services -name "*.yaml" -exec sed -i.bak "s/PROJECT_ID/$PROJECT_ID/g" {} \;

echo "🚀 Deploying in order of dependencies..."

# 1. Deploy secrets first
echo "🔐 Deploying secrets..."
kubectl apply -f k8s/secrets.yaml

# 2. Deploy databases
echo "📦 Deploying databases..."
kubectl apply -f k8s/databases/

echo "⏳ Waiting for databases to be ready..."
wait_for_deployment "mysql" "default"
wait_for_deployment "mongodb" "default"
wait_for_deployment "zookeeper" "default"
wait_for_deployment "kafka" "default"
wait_for_deployment "schema-registry" "default"

# 3. Deploy Keycloak (depends on MySQL)
echo "🔐 Deploying Keycloak..."
kubectl apply -f k8s/auth/keycloak.yaml
wait_for_deployment "keycloak-mysql" "default"
wait_for_deployment "keycloak" "default"

# 4. Deploy monitoring stack
echo "📊 Deploying monitoring stack..."
kubectl apply -f k8s/monitoring/
wait_for_deployment "prometheus" "default"
wait_for_deployment "grafana" "default"
wait_for_deployment "tempo" "default"
wait_for_deployment "loki" "default"

# 5. Deploy microservices (depends on databases and Keycloak)
echo "🔧 Deploying microservices..."
kubectl apply -f k8s/services/

# 5.5. Deploy gateway proxy for LoadBalancer
echo "🔗 Deploying gateway proxy..."
kubectl apply -f k8s/gateway-proxy.yaml

echo "⏳ Waiting for microservices to be ready..."
wait_for_deployment "product-service" "default"
wait_for_deployment "inventory-service" "default"
wait_for_deployment "order-service" "default"
wait_for_deployment "notification-service" "default"
wait_for_deployment "api-gateway" "default"
wait_for_deployment "frontend" "default"
wait_for_deployment "microservices-gateway" "default"

# 6. Install NGINX Ingress Controller
echo "🌐 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# 7. Deploy ingress
echo "🌐 Deploying ingress..."
kubectl apply -f k8s/ingress.yaml

echo "✅ Application deployed successfully!"

# Show useful information
echo ""
echo "📝 Application Information:"
echo "=========================="

# Get LoadBalancer IP
echo "Getting external IP address (this may take a few minutes)..."
EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
    echo "Waiting for external IP..."
    EXTERNAL_IP=$(kubectl get svc microservices-loadbalancer --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    if [ -z "$EXTERNAL_IP" ]; then
        sleep 30
    fi
done

echo ""
echo "🎉 Deployment completed!"
echo "🔗 Application URLs:"
echo "   Frontend: http://$EXTERNAL_IP"
echo "   API Gateway: http://$EXTERNAL_IP:9000"
echo "   Keycloak: http://$EXTERNAL_IP:8080"
echo "   Grafana: http://$EXTERNAL_IP:3000"
echo ""
echo "📊 Monitoring:"
echo "   Grafana Dashboard: http://$EXTERNAL_IP:3000"
echo "   Prometheus: http://$EXTERNAL_IP:9090"
echo ""
echo "🔐 Default Credentials:"
echo "   Keycloak Admin: admin/admin"
echo "   Grafana: admin/admin (if authentication is enabled)"
echo ""
echo "📋 Useful Commands:"
echo "   Check pods: kubectl get pods"
echo "   Check services: kubectl get services"
echo "   View logs: kubectl logs -f deployment/<service-name>"
echo "   Scale service: kubectl scale deployment <service-name> --replicas=<number>"
echo ""
echo "⚠️  Note: If using a custom domain, update /etc/hosts:"
echo "   $EXTERNAL_IP microservices.local"

# Cleanup backup files
find k8s/services -name "*.yaml.bak" -delete