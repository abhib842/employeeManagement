# Employee Management API - Minikube Deployment

This guide will help you deploy the Employee Management API to Minikube with persistent storage and Ingress support.

## 🚀 Quick Start

### Prerequisites

1. **Minikube** - Local Kubernetes cluster
2. **kubectl** - Kubernetes command-line tool
3. **Docker** - Container runtime
4. **OpenSSL** - For password generation

### Installation

```bash
# Install Minikube (if not already installed)
# macOS
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Windows
# Download from: https://minikube.sigs.k8s.io/docs/start/
```

## 📋 Deployment Steps

### 1. Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start --driver=docker --memory=4096 --cpus=2

# Verify Minikube is running
minikube status
```

### 2. Enable Required Addons

```bash
# Enable Ingress addon for external access
minikube addons enable ingress

# Enable storage-provisioner for persistent volumes
minikube addons enable storage-provisioner

# Verify addons are enabled
minikube addons list
```

### 3. Deploy the Application

```bash
# Make the deployment script executable
chmod +x k8s/deploy-minikube.sh

# Deploy the complete application
./k8s/deploy-minikube.sh deploy
```

This script will:
- ✅ Check Minikube status and start if needed
- ✅ Enable required addons
- ✅ Generate random MySQL passwords
- ✅ Create Kubernetes secrets
- ✅ Build and load Docker image to Minikube
- ✅ Deploy MySQL with persistent storage
- ✅ Deploy Flask application
- ✅ Show deployment status and access information

## 🌐 Accessing the API

### Method 1: Using /etc/hosts (Recommended)

```bash
# Get Minikube IP
minikube ip

# Add to /etc/hosts (replace with actual IP)
echo "$(minikube ip) employee-api.local" | sudo tee -a /etc/hosts

# Test the API
curl http://employee-api.local/health
```

### Method 2: Using Host Header

```bash
# Test without modifying /etc/hosts
curl -H "Host: employee-api.local" http://$(minikube ip)/health
```

### Method 3: Port Forward (Alternative)

```bash
# Port forward the service directly
kubectl port-forward -n employee-management svc/employee-flask-service 8080:80

# Access via localhost
curl http://localhost:8080/health
```

## 📊 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/employees` | Add new employee |
| GET | `/employees/{id}` | Get employee by ID |
| GET | `/employees` | Get all employees |

### Example API Usage

```bash
# Health check
curl http://employee-api.local/health

# Add employee
curl -X POST http://employee-api.local/employees \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "department": "Engineering",
    "position": "Software Engineer",
    "salary": 75000.00,
    "hire_date": "2024-01-15"
  }'

# Get employee by ID
curl http://employee-api.local/employees/1

# Get all employees
curl http://employee-api.local/employees
```

## 🔧 Management Commands

### Check Status

```bash
# Show deployment status
./k8s/deploy-minikube.sh status

# Show recent logs
./k8s/deploy-minikube.sh logs

# Show access information
./k8s/deploy-minikube.sh access
```

### Cleanup

```bash
# Clean up all resources
./k8s/deploy-minikube.sh cleanup
```

## 💾 Persistent Storage

The MySQL database uses persistent storage that survives pod restarts:

- **Storage Class**: `standard` (Minikube default)
- **Storage Size**: 1Gi
- **Access Mode**: ReadWriteOnce
- **Data Persistence**: Data persists across pod restarts and Minikube restarts

### Verify Storage

```bash
# Check PVC status
kubectl get pvc -n employee-management

# Check persistent volumes
kubectl get pv
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Minikube Not Starting

```bash
# Check Minikube status
minikube status

# Delete and recreate if needed
minikube delete
minikube start --driver=docker --memory=4096 --cpus=2
```

#### 2. Ingress Not Working

```bash
# Check if ingress addon is enabled
minikube addons list | grep ingress

# Enable if not enabled
minikube addons enable ingress

# Check ingress controller
kubectl get pods -n ingress-nginx
```

#### 3. Image Loading Issues

```bash
# Check if image is loaded
minikube image ls | grep employee-flask-app

# Reload image if needed
minikube image load employee-flask-app:latest
```

#### 4. Database Connection Issues

```bash
# Check MySQL pod status
kubectl get pods -n employee-management -l app=employee-mysql

# Check MySQL logs
kubectl logs -n employee-management -l app=employee-mysql

# Check Flask app logs
kubectl logs -n employee-management -l app=employee-flask-app
```

#### 5. Storage Issues

```bash
# Check storage provisioner
kubectl get pods -n kube-system | grep storage-provisioner

# Check PVC status
kubectl describe pvc mysql-pvc -n employee-management
```

### Debug Commands

```bash
# Get detailed pod information
kubectl describe pod -n employee-management -l app=employee-mysql
kubectl describe pod -n employee-management -l app=employee-flask-app

# Check events
kubectl get events -n employee-management --sort-by='.lastTimestamp'

# Check service endpoints
kubectl get endpoints -n employee-management
```

## 🔐 Security Notes

- **Passwords**: Random passwords are generated for each deployment
- **Secrets**: Passwords are stored in Kubernetes secrets
- **Network**: Services are exposed via Ingress with proper annotations
- **Storage**: Data is persisted using Minikube's storage provisioner

## 📈 Scaling

```bash
# Scale Flask application
kubectl scale deployment employee-flask-app -n employee-management --replicas=3

# Check scaling status
kubectl get pods -n employee-management -l app=employee-flask-app
```

## 🧹 Cleanup

### Complete Cleanup

```bash
# Remove all resources
./k8s/deploy-minikube.sh cleanup

# Stop Minikube (optional)
minikube stop

# Delete Minikube cluster (optional)
minikube delete
```

### Partial Cleanup

```bash
# Remove only the application
kubectl delete namespace employee-management

# Remove specific resources
kubectl delete -f k8s/flask-deployment-minikube.yaml
kubectl delete -f k8s/mysql-deployment-minikube.yaml
```

## 📝 Notes

- **Data Persistence**: MySQL data persists across pod restarts
- **Resource Limits**: Configured for development environment
- **Network Access**: Uses Minikube's ingress controller
- **Image Loading**: Docker images are loaded directly into Minikube
- **Password Management**: Random passwords generated for each deployment

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Check Minikube and addon status
4. Review pod logs for specific errors
5. Ensure sufficient system resources (4GB RAM, 2 CPUs recommended) 