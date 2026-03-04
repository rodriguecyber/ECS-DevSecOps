#!/usr/bin/env bash
# Debug ECS image pull failures: show what image the service uses and whether it exists in ECR.
# Usage: ./scripts/debug-ecr-pull.sh [CLUSTER] [SERVICE] [REGION]
# Example: ./scripts/debug-ecr-pull.sh secure-webapp-dev-cluster secure-webapp-dev-service eu-north-1

set -e

CLUSTER="${1:-secure-webapp-dev-cluster}"
SERVICE="${2:-secure-webapp-dev-service}"
REGION="${3:-eu-north-1}"

echo "=== ECS image pull debug ==="
echo "Cluster: $CLUSTER | Service: $SERVICE | Region: $REGION"
echo

# 1. Current task definition
TASK_DEF_ARN=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION" \
  --query 'services[0].taskDefinition' --output text 2>/dev/null || true)
if [[ -z "$TASK_DEF_ARN" || "$TASK_DEF_ARN" == "None" ]]; then
  echo "ERROR: Could not get task definition for service (service missing or no access)."
  exit 1
fi
echo "Current task definition: $TASK_DEF_ARN"

# 2. Container image from task definition
IMAGE=$(aws ecs describe-task-definition --task-definition "$TASK_DEF_ARN" --region "$REGION" \
  --query 'taskDefinition.containerDefinitions[0].image' --output text 2>/dev/null || true)
EXECUTION_ROLE_ARN=$(aws ecs describe-task-definition --task-definition "$TASK_DEF_ARN" --region "$REGION" \
  --query 'taskDefinition.executionRoleArn' --output text 2>/dev/null || true)

if [[ -z "$IMAGE" ]]; then
  echo "ERROR: No container image in task definition."
  exit 1
fi
echo "Container image: $IMAGE"
echo "Execution role:  $EXECUTION_ROLE_ARN"
echo

# 3. Parse repo and tag
# Image format: 265267290744.dkr.ecr.eu-north-1.amazonaws.com/secure-webapp:v10-b1b0711
REPO_REGION=$(echo "$IMAGE" | sed -n 's/.*\.dkr\.ecr\.\([^.]*\)\.amazonaws\.com.*/\1/p')
REPO_NAME=$(echo "$IMAGE" | sed -n 's/.*\.amazonaws\.com\/\([^:]*\).*/\1/p')
TAG=$(echo "$IMAGE" | sed -n 's/.*:\(.*\)/\1/p')

if [[ -z "$REPO_NAME" ]]; then
  echo "Could not parse ECR repo from image URI (not in ECR format?)."
else
  echo "--- ECR check ---"
  echo "Repo: $REPO_NAME | Tag: $TAG | Region: ${REPO_REGION:-$REGION}"
  ECR_REGION="${REPO_REGION:-$REGION}"
  if aws ecr describe-images --repository-name "$REPO_NAME" --image-ids imageTag="$TAG" --region "$ECR_REGION" &>/dev/null; then
    echo "OK: Image exists in ECR."
  else
    echo "FAIL: Image NOT found in ECR (wrong tag, repo, or region)."
    echo "Tags in repo:"
    aws ecr list-images --repository-name "$REPO_NAME" --region "$ECR_REGION" --query 'imageIds[*].imageTag' --output text 2>/dev/null || echo "  (could not list)"
  fi
fi
echo

# 4. Recent service events (pull/role errors show here)
echo "--- Recent ECS service events ---"
aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION" \
  --query 'services[0].events[0:8].[createdAt,message]' --output table 2>/dev/null || true
echo
echo "If you see CannotPullContainerError or AccessDenied: check execution role has ECR pull (ecr:GetAuthorizationToken + BatchGetImage)."
echo "If tasks use private subnets: ensure NAT Gateway or ECR VPC endpoints exist."
