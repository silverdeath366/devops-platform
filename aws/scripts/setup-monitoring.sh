#!/bin/bash
# Setup monitoring with Prometheus and Grafana

set -e

NAMESPACE=${NAMESPACE:-monitoring}
CLUSTER_NAME=${CLUSTER_NAME:-devops-platform-eks}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "📊 Setting up Monitoring Stack"
echo "=============================="
echo ""

# Create monitoring namespace
kubectl create namespace $NAMESPACE 2>/dev/null || true

# Add Helm repos
echo "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
echo ""
echo "Installing Prometheus..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace $NAMESPACE \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --set grafana.adminPassword=admin123 \
    --wait

echo "✅ Prometheus installed"

# Install Grafana dashboards for services
echo ""
echo "Configuring Grafana..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: devops-dashboards
  namespace: $NAMESPACE
  labels:
    grafana_dashboard: "1"
data:
  devops-overview.json: |
    {
      "dashboard": {
        "title": "DevOps Platform Overview",
        "panels": [
          {
            "title": "Service Health",
            "targets": [
              {
                "expr": "up{job=~\".*devops.*\"}"
              }
            ]
          }
        ]
      }
    }
EOF

echo ""
echo "✅ Monitoring stack installed!"
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n $NAMESPACE svc/prometheus-grafana 3000:80"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "Access Prometheus:"
echo "  kubectl port-forward -n $NAMESPACE svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo ""
echo "View service metrics:"
echo "  curl http://localhost:8001/metrics"

