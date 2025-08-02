#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="employee-management"
SECRET_NAME="mysql-secret"
MYSQL_DEPLOYMENT="k8s/mysql-deployment-minikube.yaml"
FLASK_DEPLOYMENT="k8s/flask-deployment-minikube.yaml"
NAMESPACE_FILE="k8s/namespace.yaml"

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Minikube status
check_minikube() {
    print_status "Checking Minikube status..."
    
    if ! command_exists minikube; then
        print_error "Minikube is not installed. Please install Minikube first."
        echo "Installation guide: https://minikube.sigs.k8s.io/docs/start/"
        exit 1
    fi
    
    if ! minikube status --format='{{.Host}}' | grep -q "Running"; then
        print_warning "Minikube is not running. Starting Minikube..."
        minikube start --driver=docker --memory=3096 --cpus=2
        if [ $? -ne 0 ]; then
            print_error "Failed to start Minikube"
            exit 1
        fi
    fi
    
    print_success "Minikube is running"
}

# Function to enable Minikube addons
enable_addons() {
    print_status "Enabling Minikube addons..."
    
    # Enable ingress addon
    if ! minikube addons list | grep -q "ingress.*enabled"; then
        print_status "Enabling ingress addon..."
        minikube addons enable ingress
        sleep 10  # Wait for ingress to be ready
    fi
    
    # Enable storage-provisioner addon
    if ! minikube addons list | grep -q "storage-provisioner.*enabled"; then
        print_status "Enabling storage-provisioner addon..."
        minikube addons enable storage-provisioner
    fi
    
    print_success "Minikube addons enabled"
}

# Function to generate random passwords
generate_passwords() {
    print_status "Generating random passwords..."
    
    # Generate random passwords
    ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    USER_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    print_success "Random passwords generated"
}

# Function to create secret
create_secret() {
    print_status "Creating Kubernetes secret with random passwords..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Delete existing secret if it exists
    kubectl delete secret $SECRET_NAME -n $NAMESPACE --ignore-not-found=true
    
    # Create new secret
    kubectl create secret generic $SECRET_NAME \
        --from-literal=root-password="$ROOT_PASSWORD" \
        --from-literal=user-password="$USER_PASSWORD" \
        --namespace=$NAMESPACE
    
    if [ $? -eq 0 ]; then
        print_success "Secret created successfully!"
    else
        print_error "Failed to create secret"
        exit 1
    fi
}

# Function to build and load Docker image
build_and_load_image() {
    print_status "Building and loading Docker image to Minikube..."
    
    # Build the Docker image
    print_status "Building Docker image..."
    docker build -t employee-flask-app:latest .
    
    if [ $? -ne 0 ]; then
        print_error "Failed to build Docker image"
        exit 1
    fi
    
    # Load image into Minikube
    print_status "Loading image into Minikube..."
    minikube image load employee-flask-app:latest
    
    if [ $? -ne 0 ]; then
        print_error "Failed to load image into Minikube"
        exit 1
    fi
    
    print_success "Docker image built and loaded successfully"
}

# Function to deploy applications
deploy_applications() {
    print_status "Deploying applications to Kubernetes..."
    
    # Deploy MySQL
    print_status "Deploying MySQL..."
    kubectl apply -f $MYSQL_DEPLOYMENT
    
    if [ $? -ne 0 ]; then
        print_error "Failed to deploy MySQL"
        exit 1
    fi
    
    # Wait for MySQL to be ready
    print_status "Waiting for MySQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=employee-mysql -n $NAMESPACE --timeout=300s
    
    if [ $? -ne 0 ]; then
        print_error "MySQL failed to become ready"
        exit 1
    fi
    
    # Deploy Flask app
    print_status "Deploying Flask application..."
    kubectl apply -f $FLASK_DEPLOYMENT
    
    if [ $? -ne 0 ]; then
        print_error "Failed to deploy Flask application"
        exit 1
    fi
    
    print_success "Applications deployed successfully"
}

# Function to show status
show_status() {
    print_status "Checking deployment status..."
    
    echo ""
    echo -e "${BLUE}📊 Pod Status:${NC}"
    kubectl get pods -n $NAMESPACE
    
    echo ""
    echo -e "${BLUE}🔗 Services:${NC}"
    kubectl get services -n $NAMESPACE
    
    echo ""
    echo -e "${BLUE}🌐 Ingress:${NC}"
    kubectl get ingress -n $NAMESPACE
    
    echo ""
    echo -e "${BLUE}💾 PVC Status:${NC}"
    kubectl get pvc -n $NAMESPACE
}

# Function to show access information
show_access_info() {
    print_status "Access Information:"
    
    echo ""
    echo -e "${GREEN}🌐 API Access:${NC}"
    echo -e "  Minikube IP: ${YELLOW}$(minikube ip)${NC}"
    echo -e "  Ingress Host: ${YELLOW}employee-api.local${NC}"
    echo ""
    echo -e "${BLUE}📝 To access the API:${NC}"
    echo -e "  1. Add to /etc/hosts: ${YELLOW}$(minikube ip) employee-api.local${NC}"
    echo -e "  2. Or use: ${YELLOW}curl -H 'Host: employee-api.local' http://$(minikube ip)${NC}"
    echo ""
    echo -e "${GREEN}🔍 Health Check:${NC}"
    echo -e "  curl -H 'Host: employee-api.local' http://$(minikube ip)/health"
    echo ""
    echo -e "${GREEN}📋 API Endpoints:${NC}"
    echo -e "  POST /employees - Add employee"
    echo -e "  GET /employees/{id} - Get employee by ID"
    echo -e "  GET /employees - Get all employees"
    echo -e "  GET /health - Health check"
    echo -e "Running minikube tunnel to access the ingress employee-flask-ingress locally"
    minikube tunnel
}

# Function to show logs
show_logs() {
    print_status "Recent logs:"
    
    echo ""
    echo -e "${BLUE}📝 MySQL Logs:${NC}"
    kubectl logs -l app=employee-mysql -n $NAMESPACE --tail=10
    
    echo ""
    echo -e "${BLUE}📝 Flask App Logs:${NC}"
    kubectl logs -l app=employee-flask-app -n $NAMESPACE --tail=10
}

# Function to clean up
cleanup() {
    print_status "Cleaning up deployment..."
    
    kubectl delete -f $FLASK_DEPLOYMENT --ignore-not-found=true
    kubectl delete -f $MYSQL_DEPLOYMENT --ignore-not-found=true
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    
    print_success "Cleanup completed"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy      - Deploy the complete application to Minikube"
    echo "  status      - Show deployment status"
    echo "  logs        - Show recent logs"
    echo "  access      - Show access information"
    echo "  cleanup     - Clean up all resources"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy   # Deploy the application"
    echo "  $0 status   # Check deployment status"
    echo "  $0 logs     # View logs"
}

# Main execution
case "${1:-deploy}" in
    "deploy")
        check_minikube
        enable_addons
        generate_passwords
        create_secret
        build_and_load_image
        deploy_applications
        show_status
        show_access_info
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "access")
        show_access_info
        ;;
    "cleanup")
        cleanup
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 
