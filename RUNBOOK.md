# StartTech — Operations Runbook

This runbook covers common operational procedures, incident response steps, and troubleshooting guides for the StartTech infrastructure.

---

## Table of Contents
- [Access & Credentials](#access--credentials)
- [Deployment Procedures](#deployment-procedures)
- [Health Checks](#health-checks)
- [Incident Response](#incident-response)
- [Scaling Procedures](#scaling-procedures)
- [Rollback Procedures](#rollback-procedures)
- [Common Issues](#common-issues)

---

## Access & Credentials

### AWS Console
- Account ID: `225201316405`
- Region: `us-east-1`

### SSH / SSM Access to EC2
Prefer SSM over SSH — no open port 22 required:
```bash
# List running backend instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev-backend-instance" \
            "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,State.Name]" \
  --output table

# Start SSM session
aws ssm start-session --target <instance-id>
View Running Container on instance
# After SSM session
sudo docker ps
sudo docker logs muchtodo-backend --tail 50 -f
Deployment Procedures
Backend Deployment (via CI/CD — preferred)
1. Push code to main branch of starttech-application repo
2. GitHub Actions: test → build → push ECR → await approval
3. Approve deployment in GitHub Actions UI (production environment)
4. ASG instance refresh starts automatically
5. Monitor progress in AWS Console → EC2 → Auto Scaling Groups → dev-backend-asg → Instance Refresh

Backend Deployment (manual)
# On control VM or any machine with Docker + AWS credentials
./scripts/deploy-backend.sh           # deploys :latest
./scripts/deploy-backend.sh a1b2c3d4  # deploys specific tag

Frontend Deployment (via CI/CD — preferred)
1. Push code to main branch in Client/ directory
2. GitHub Actions: build → audit → S3 sync → CloudFront invalidation
3. Done — no approval gate for frontend (low risk)

Frontend Deployment (manual)
cd starttech-application
# Build first
cd Client && npm ci && npm run build && cd ..

# Deploy
./scripts/deploy-frontend.sh dev-starttech-frontend-jare-1

# With CloudFront invalidation (once account verified)
./scripts/deploy-frontend.sh dev-starttech-frontend-jare-1 <distribution-id>

Infrastructure Deployment (via CI/CD — preferred)
1. Push Terraform changes to main branch of starttech-infra repo
2. GitHub Actions: fmt → init → validate → tfsec → plan → await approval
3. Approve in GitHub Actions UI
4. Terraform apply runs automatically

Infrastructure Deployment (manual)
cd starttech-infra
export TF_VAR_mongo_uri="mongodb+srv://..."
export TF_VAR_jwt_secret_key="..."
./scripts/deploy-infrastructure.sh plan   # review changes
./scripts/deploy-infrastructure.sh apply  # apply changes

Health Checks
Quick application health check
# Replace with your ALB DNS name
ALB="dev-backend-alb-2008053916.us-east-1.elb.amazonaws.com"

# Ping endpoint
curl -s http://$ALB/ping

# Full health check with retries
./scripts/health-check.sh $ALB

# Expected response
# {"message":"pong"}

Check ALB target health
Bash
# Get target group ARN
TG_ARN=$(aws elbv2 describe-target-groups \
  --names dev-backend-tg \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text)

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --query "TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]" \
  --output table

Check ASG status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names dev-backend-asg \
  --query "AutoScalingGroups[0].{
    Min:MinSize,
    Max:MaxSize,
    Desired:DesiredCapacity,
    InService:Instances[?LifecycleState=='InService']|length(@)
  }" \
  --output table

Check Redis connectivity from EC2
# In SSM session on backend EC2
sudo docker exec muchtodo-backend sh -c \
  'wget -qO- http://localhost:8080/health'

Incident Response
ALB 5XX Errors {#alb-5xx-errors}
Symptoms: CloudWatch alarm dev-alb-5xx-errors triggered
Diagnosis steps:
# 1. Check ALB error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_ELB_5XX_Count \
  --dimensions Name=LoadBalancer,Value=app/dev-backend-alb/b47618a0ce377ab3 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum

# 2. Check application logs
aws logs filter-log-events \
  --log-group-name /starttech/backend \
  --start-time $(date -d '1 hour ago' +%s000) \
  --filter-pattern "ERROR"

# 3. Check target health (see Health Checks section above)

Resolution:
If all targets unhealthy → likely app crash → check logs → rollback if needed
If some targets unhealthy → ASG will replace them automatically
If logs show DB errors → check MongoDB Atlas status
If logs show Redis errors → Redis may be unavailable, set ENABLE_CACHE=false temporarily

High CPU {#high-cpu}
Symptoms: CloudWatch alarm dev-backend-high-cpu triggered
Diagnosis steps:
High CPU {#high-cpu}
Symptoms: CloudWatch alarm dev-backend-high-cpu triggered
# Check current CPU across all ASG instances
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=dev-backend-asg \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average

Resolution:
If sustained > 80% → manually increase ASG desired capacity
If spike → likely traffic burst → ASG scale-out policy will trigger
Bash

# Manual scale-out
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name dev-backend-asg \
  --desired-capacity 4

Unhealthy Hosts {#unhealthy-hosts}
Symptoms: CloudWatch alarm dev-backend-unhealthy-hosts triggered
Diagnosis steps:# Check which instances are unhealthy
TG_ARN=$(aws elbv2 describe-target-groups \
  --names dev-backend-tg \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text)

aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN

Resolution:
ASG will automatically replace unhealthy instances (health_check_type = "ELB")
If not replacing → check ASG activity history:
Bash

aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name dev-backend-asg \
  --max-items 10

edis High CPU {#redis-high-cpu}
Symptoms: CloudWatch alarm dev-redis-high-cpu triggered
Resolution:
Check cache usage patterns via Logs Insights query #6
If memory pressure → review maxmemory-policy (currently allkeys-lru)
Temporary workaround — disable caching:

# Update .env on each instance via SSM
# Set ENABLE_CACHE=false and restart container

# Use Logs Insights query #3 — Top 10 slowest API requests
# Check MongoDB Atlas performance dashboard
# Check Redis latency

ASG Capacity {#asg-capacity}
Symptoms: CloudWatch alarm dev-asg-min-capacity triggered — fewer than 2 instances in service
Resolution:
Bash

# Force desired capacity back to minimum
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name dev-backend-asg \
  --desired-capacity 2

# Check why instances terminated
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name dev-backend-asg \
  --max-items 20

Scaling Procedures
Manual Scale-Out

aws autoscaling set-desired-capacity \
  --auto-scaling-group-name dev-backend-asg \
  --desired-capacity 2

Update ASG min/max (via Terraform — preferred)
Edit terraform/main.tf compute module:
Hcl

# List available ECR image tags
aws ecr list-images \
  --repository-name dev-starttech-backend \
  --filter tagStatus=TAGGED \
  --query "imageIds[*].imageTag" \
  --output table

# Rollback to a previous tag
./scripts/rollback.sh <previous-tag>
# Example: ./scripts/rollback.sh a1b2c3d4

Frontend Rollback
S3 bucket has versioning enabled. To restore a previous version:
Bash

# List object versions
aws s3api list-object-versions \
  --bucket dev-starttech-frontend-jare-1 \
  --prefix index.html

# Restore a specific version
aws s3api copy-object \
  --bucket dev-starttech-frontend-jare-1 \
  --copy-source "dev-starttech-frontend-jare-1/index.html?versionId=<version-id>" \
  --key index.html

Infrastructure Rollback
Bash

cd terraform

# View previous state versions in S3
aws s3api list-object-versions \
  --bucket adejare-starttech-tf-state \
  --prefix global/terraform.tfstate

# Revert a specific Terraform resource
terraform state show <resource>
terraform apply -target=<resource> -auto-approve

Common Issues
IssueLikely CauseFix
Container not startingWrong ECR image tag or image not in ECRPush image first, then refresh ASG
/ping returns 502Container crashed or not runningCheck docker logs muchtodo-backend via SSM
Redis connection refusedTLS mismatchVerify REDIS_ADDR in .env uses correct endpoint
MongoDB auth failedRotated credentialsUpdate MONGO_URI secret and redeploy
ECR pull deniedIAM role missing ECR policyVerify AmazonEC2ContainerRegistryReadOnly attached
Terraform state lockPrevious run crashedCheck S3 for .tflock file and remove if stale
GitHub Actions fails on tfsecNew HIGH severity findingReview finding, add .tfsecignore if acceptable, fix if not
CloudFront returns 403Account not verifiedContact AWS Support — feature-flagged until resolved
