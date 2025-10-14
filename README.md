# Microservices Shop - GKE Deployment Guide

This project is a complete microservices application ready for deployment on Google Kubernetes Engine (GKE). It includes all necessary configurations, Dockerfiles, Kubernetes manifests, and deployment scripts.

## Architecture Overview

The application consists of the following services:

### Core Services
- **API Gateway** (Port 9000): Entry point for all requests, handles routing and authentication
- **Product Service** (Port 8080): Manages product catalog using MongoDB
- **Order Service** (Port 8081): Handles order processing using MySQL and Kafka
- **Inventory Service** (Port 8082): Manages inventory using MySQL
- **Notification Service** (Port 8083): Sends notifications via email, consumes from Kafka
- **Frontend** (Port 80): Angular application served via Nginx

### Infrastructure Services
- **MySQL**: Database for Order and Inventory services
- **MongoDB**: Database for Product service
- **Kafka + Zookeeper**: Message queue for order events
- **Schema Registry**: Manages Kafka message schemas
- **Keycloak**: Authentication and authorization server
- **Prometheus**: Metrics collection
- **Grafana**: Monitoring dashboards
- **Tempo**: Distributed tracing
- **Loki**: Log aggregation

## Prerequisites

Before deploying, ensure you have:

1. **Google Cloud Platform Account** with billing enabled
2. **gcloud CLI** installed and configured
3. **kubectl** installed
4. **Docker** installed and running
5. **Git** for version control

### Setup GCP Project

```bash
# Set your project ID
export GOOGLE_CLOUD_PROJECT="your-project-id"

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

## Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd AnalisisFinal
```

### 2. Create GKE Cluster

```bash
chmod +x scripts/*.sh
./scripts/setup-gke.sh
```

This will create:
- GKE cluster with 3 nodes
- Node pool with auto-scaling
- Required firewall rules

### 3. Build and Push Docker Images

```bash
./scripts/build-images.sh
```

This will:
- Build Docker images for all services
- Push them to Google Container Registry
- Tag images with both `latest` and commit hash

### 4. Deploy Application

```bash
./scripts/deploy.sh
```

This will deploy in order:
1. Databases (MySQL, MongoDB, Kafka)
2. Infrastructure services (Keycloak, monitoring)
3. Application services
4. Ingress controller

### 5. Access the Application

After deployment, get the external IP:

```bash
kubectl get ingress microservices-ingress
```

Access the services:
- **Frontend**: `http://<EXTERNAL-IP>/`
- **API Gateway**: `http://<EXTERNAL-IP>/api/`
- **Keycloak**: `http://<EXTERNAL-IP>/auth/`
- **Grafana**: `http://<EXTERNAL-IP>/grafana/`

## Manual Deployment Steps

If you prefer to deploy manually:

### 1. Deploy Databases

```bash
kubectl apply -f k8s/databases/
```

### 2. Deploy Authentication

```bash
kubectl apply -f k8s/auth/
```

### 3. Deploy Monitoring

```bash
kubectl apply -f k8s/monitoring/
```

### 4. Deploy Services

```bash
kubectl apply -f k8s/services/
```

### 5. Deploy Ingress

```bash
kubectl apply -f k8s/ingress.yaml
```

## Configuration

### Environment Variables

Each service supports the following profiles:
- `default`: Local development
- `k8s`: Kubernetes deployment

The services automatically use `k8s` profile when deployed to Kubernetes.

### Database Initialization

- MySQL databases are automatically created with initialization scripts
- MongoDB is configured with authentication
- Kafka topics are created automatically

### Security

- All services run as non-root users
- Network policies can be applied for additional security
- Keycloak provides OAuth2/OIDC authentication
- TLS can be enabled with cert-manager

## Monitoring and Observability

### Metrics (Prometheus)
Access Prometheus at `http://<EXTERNAL-IP>/prometheus`

Key metrics:
- HTTP request rates and latencies
- Database connection pools
- JVM metrics
- Custom business metrics

### Dashboards (Grafana)
Access Grafana at `http://<EXTERNAL-IP>/grafana`

Pre-configured dashboards:
- Application overview
- Service-specific metrics
- Infrastructure monitoring
- Kafka metrics

### Distributed Tracing (Tempo)
Integrated with Grafana for request tracing across services

### Logging (Loki)
Centralized log aggregation accessible through Grafana

## Scaling

### Horizontal Pod Autoscaling

HPA is configured for all services based on:
- CPU utilization (70% target)
- Memory utilization (80% target)

### Vertical Pod Autoscaling

VPA can be enabled for automatic resource right-sizing.

### Cluster Autoscaling

The node pool is configured with auto-scaling:
- Min nodes: 1
- Max nodes: 10

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending state**
   ```bash
   kubectl describe pods <pod-name>
   # Check resource requests and node capacity
   ```

2. **Database connection issues**
   ```bash
   kubectl logs <service-pod-name>
   kubectl get svc mysql mongodb kafka
   ```

3. **Image pull errors**
   ```bash
   # Ensure images are pushed to registry
   gcloud container images list --repository=gcr.io/$GOOGLE_CLOUD_PROJECT
   ```

### Useful Commands

```bash
# Check all pods status
kubectl get pods --all-namespaces

# View service logs
kubectl logs -f deployment/<service-name>

# Port forward for local access
kubectl port-forward service/<service-name> <local-port>:<service-port>

# Scale deployment
kubectl scale deployment <service-name> --replicas=3

# Update image
kubectl set image deployment/<service-name> <container-name>=gcr.io/$GOOGLE_CLOUD_PROJECT/<service-name>:new-tag
```

## Development Workflow

### Building Changes

1. Make code changes
2. Build and push updated image:
   ```bash
   ./scripts/build-images.sh
   ```
3. Update deployment:
   ```bash
   kubectl rollout restart deployment/<service-name>
   ```

### Rolling Updates

```bash
# Update with new image
kubectl set image deployment/<service-name> <container>=gcr.io/$PROJECT_ID/<service>:new-tag

# Monitor rollout
kubectl rollout status deployment/<service-name>

# Rollback if needed
kubectl rollout undo deployment/<service-name>
```

## Cleanup

To remove all resources:

```bash
./scripts/cleanup.sh
```

This will:
- Delete all Kubernetes resources
- Delete the GKE cluster
- Clean up persistent volumes

## Cost Optimization

- Use preemptible nodes for non-production environments
- Enable cluster autoscaling
- Set appropriate resource requests and limits
- Use Horizontal Pod Autoscaling
- Monitor costs in GCP Console

## Security Best Practices

- Enable Workload Identity for GKE
- Use Google Cloud Security Command Center
- Implement network policies
- Regular security updates
- Enable audit logging
- Use Google Cloud Binary Authorization

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review Kubernetes and application logs
3. Consult GKE documentation
4. Check service mesh configuration if applicable

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test locally
4. Update documentation
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.