#!/bin/bash
# Install monitoring stack (Prometheus + Grafana)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing Monitoring Stack${NC}"
echo ""

# Install monitoring namespace and Prometheus
echo "1. Installing Prometheus..."
kubectl apply -f k8s/monitoring/prometheus.yaml

echo ""
echo "2. Waiting for Prometheus to be ready..."
kubectl wait --for=condition=ready pod \
    -l app=prometheus \
    -n monitoring \
    --timeout=120s

echo ""
echo "3. Waiting for Grafana to be ready..."
kubectl wait --for=condition=ready pod \
    -l app=grafana \
    -n monitoring \
    --timeout=120s

echo ""
echo -e "${GREEN}✓ Monitoring stack installed!${NC}"
echo ""
echo "Access Prometheus:"
echo "  kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "  Then open: http://localhost:9090"
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n monitoring svc/grafana 3000:80"
echo "  Then open: http://localhost:3000"
echo "  Default credentials: admin/admin"
echo ""
echo "Configure Grafana data source:"
echo "  URL: http://prometheus.monitoring.svc.cluster.local:9090"

