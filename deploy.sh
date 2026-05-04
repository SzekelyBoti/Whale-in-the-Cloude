#!/bin/bash
set -e

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─── Config ───────────────────────────────────────────────────────────────────
REGION="eu-north-1"
TERRAFORM_DIR="./terraform"
APP_DIR="./app"
NGINX_DIR="./nginx"
LAMBDA_DIR="./lambda"
KEY_FILE="whale-key.pem"

log "Fetching AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_BASE="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
APP_REPO="${ECR_BASE}/whale-app"
NGINX_REPO="${ECR_BASE}/whale-nginx"

# ─── Usage ────────────────────────────────────────────────────────────────────
usage() {
  echo ""
  echo "Usage: ./deploy.sh [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  up        Full deploy (terraform + build + push + pull on servers)"
  echo "  destroy   Tear down all infrastructure"
  echo "  build     Build and push Docker images only"
  echo "  pull      Pull images on EC2 instances only"
  echo "  report    Invoke the Lambda report"
  echo ""
  exit 1
}

# ─── Step 1: Terraform Apply ──────────────────────────────────────────────────
terraform_apply() {
  log "Initializing Terraform..."
  cd "$TERRAFORM_DIR"
  terraform init -upgrade

  log "Running Terraform plan..."
  terraform plan -var-file="terraform.tfvars"

  log "Applying Terraform..."
  terraform apply -var-file="terraform.tfvars" -auto-approve

  success "Terraform apply complete"
  cd ..
}

# ─── Step 2: Terraform Destroy ────────────────────────────────────────────────
terraform_destroy() {
  warn "This will destroy ALL infrastructure!"
  read -p "Are you sure? Type 'yes' to confirm: " confirm
  if [ "$confirm" != "yes" ]; then
    log "Destroy cancelled."
    exit 0
  fi

  cd "$TERRAFORM_DIR"
  terraform destroy -var-file="terraform.tfvars" -auto-approve
  success "Infrastructure destroyed"
  cd ..
}

# ─── Step 3: Build & Push Docker Images ──────────────────────────────────────
build_and_push() {
  log "Logging in to ECR..."
  aws ecr get-login-password --region "$REGION" | \
    docker login --username AWS --password-stdin "$ECR_BASE"

  log "Building app image..."
  docker build -t whale-app "$APP_DIR"
  docker tag whale-app:latest "${APP_REPO}:latest"
  docker push "${APP_REPO}:latest"
  success "App image pushed"

  log "Building nginx image..."
  docker build -t whale-nginx "$NGINX_DIR"
  docker tag whale-nginx:latest "${NGINX_REPO}:latest"
  docker push "${NGINX_REPO}:latest"
  success "Nginx image pushed"
}

# ─── Step 4: Package Lambda ───────────────────────────────────────────────────
package_lambda() {
  log "Packaging Lambda function..."
  cd "$LAMBDA_DIR"
  npm install
  zip -r report.zip index.js package.json package-lock.json node_modules/
  success "Lambda packaged"
  cd ..
}

# ─── Step 5: Pull Images on EC2 Instances ────────────────────────────────────
pull_on_servers() {
  log "Getting server IPs from Terraform output..."
  cd "$TERRAFORM_DIR"
  BASTION_IP=$(terraform output -raw bastion_ssh | awk '{print $NF}')
  SERVER_IPS=$(terraform output -json server_ips | tr -d '[]"' | tr ',' ' ')
  cd ..

  log "Bastion: $BASTION_IP"
  log "Servers: $SERVER_IPS"

  if [ ! -f "$KEY_FILE" ]; then
    error "Key file '$KEY_FILE' not found in current directory"
  fi

  chmod 400 "$KEY_FILE"

  # Copy key to bastion
  log "Copying key to bastion..."
  scp -i "$KEY_FILE" \
    -o StrictHostKeyChecking=no \
    "$KEY_FILE" "ec2-user@${BASTION_IP}:~"

  for IP in $SERVER_IPS; do
    log "Pulling images on $IP..."
    ssh -i "$KEY_FILE" \
      -o StrictHostKeyChecking=no \
      -o ProxyJump="ec2-user@${BASTION_IP}" \
      "ec2-user@${IP}" bash << EOF
        chmod 400 ~/whale-key.pem
        aws ecr get-login-password --region ${REGION} | \
          docker login --username AWS --password-stdin ${ECR_BASE}
        cd /home/ec2-user
        sudo /usr/local/bin/docker-compose pull
        sudo /usr/local/bin/docker-compose up -d
        echo "Containers on ${IP}:"
        sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
EOF
    success "Done on $IP"
  done
}

# ─── Step 6: Invoke Lambda Report ────────────────────────────────────────────
invoke_report() {
  log "Invoking Lambda report..."
  aws lambda invoke \
    --function-name whale-report-lambda \
    --region "$REGION" \
    /tmp/response.json

  BODY=$(cat /tmp/response.json | python3 -c "import sys,json; b=json.load(sys.stdin); print(json.dumps(json.loads(b['body']), indent=2))")
  echo "$BODY"

  KEY=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")
  BUCKET=$(cd "$TERRAFORM_DIR" && terraform output -raw whale_reports_bucket 2>/dev/null || echo "")

  if [ -n "$BUCKET" ]; then
    log "Fetching report from S3..."
    aws s3 cp "s3://${BUCKET}/${KEY}" - --region "$REGION"
  else
    log "Report key: $KEY"
    warn "Add 'output whale_reports_bucket' to terraform outputs to auto-fetch the report"
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
case "${1:-}" in
  up)
    log "=== Starting full deployment ==="
    package_lambda
    terraform_apply
    build_and_push
    pull_on_servers
    invoke_report
    success "=== Deployment complete ==="
    ;;
  destroy)
    log "=== Destroying infrastructure ==="
    terraform_destroy
    ;;
  build)
    build_and_push
    ;;
  pull)
    pull_on_servers
    ;;
  report)
    invoke_report
    ;;
  *)
    usage
    ;;
esac