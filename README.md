# StartTech Infrastructure

Complete Infrastructure as Code for the StartTech full-stack Todo application. Built with Terraform, deployed on AWS, and automated via GitHub Actions CI/CD.

## Table of Contents

- [What This Is](#what-this-is)
- [Technology Stack](#technology-stack)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Terraform Modules](#terraform-modules)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Observability](#monitoring--observability)
- [Security](#security)
- [Operations & Troubleshooting](#operations--troubleshooting)

---

## What This Is

This repository contains the complete infrastructure for StartTech — a full-stack Todo application deployed on AWS with high availability, automatic scaling, and comprehensive observability. It covers networking, compute, storage, caching, container registry, monitoring, and state management using Terraform >= 1.10.

**Key Features:**
- Multi-tier VPC architecture with public, private app, and private cache subnets
- Auto-scaling backend (Go + Gin API) behind Application Load Balancer
- Redis ElastiCache for caching and session management
- S3 + CloudFront for frontend distribution
- CloudWatch integrated monitoring with alarms and dashboards
- GitHub Actions automation with security scanning (tfsec)
- AWS SSM Session Manager access (no SSH needed)

---

## Technology Stack

| Component | Technology | Version |
|---|---|---|
| Infrastructure as Code | Terraform | >= 1.10 |
| Backend | Go | 1.23 |
| Backend Framework | Gin | Latest |
| Container Runtime | Docker | Latest |
| Container Registry | AWS ECR | - |
| Frontend Hosting | AWS S3 | - |
| CDN | AWS CloudFront | - |
| Cache Engine | Redis | 7.0 |
| Cache Provider | AWS ElastiCache | Multi-AZ |
| Database | MongoDB Atlas | External SaaS |
| Cloud Platform | AWS | us-east-1 |
| CI/CD | GitHub Actions | - |
| Monitoring | CloudWatch | - |
| Security Scanning | tfsec | Latest |

---

## Repository Structure

```
starttech-infra/
├── .github/
│   └── workflows/
│       └── infrastructure-deploy.yml      # Terraform CI/CD: plan → approve → apply/destroy
│
├── terraform/
│   ├── backend.tf                         # S3 remote state with locking
│   ├── main.tf                            # Module composition
│   ├── providers.tf                       # AWS provider configuration
│   ├── variables.tf                       # Input variables (mongo_uri, jwt_secret_key, etc.)
│   ├── outputs.tf                         # ALB DNS, ECR URL, Redis endpoint, S3 bucket, etc.
│   ├── versions.tf                        # Terraform version constraints
│   │
│   └── modules/
│       ├── networking/                    # VPC, subnets, NAT, route tables, security groups
│       │   ├── vpc.tf
│       │   ├── subnets.tf
│       │   ├── nat.tf
│       │   ├── routing.tf
│       │   ├── security_groups.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       │
│       ├── compute/                       # ALB, ASG, EC2 launch template, IAM roles
│       │   ├── alb.tf
│       │   ├── asg.tf
│       │   ├── launch-template.tf         # Includes user_data: Docker, CloudWatch agent, ECR login
│       │   ├── iam.tf
│       │   ├── variables.tf
│       │   └── output.tf
│       │
│       ├── storage/                       # S3 bucket + CloudFront distribution
│       │   ├── s3.tf
│       │   ├── cloudfront.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       │
│       ├── cache/                         # ElastiCache Redis multi-AZ
│       │   └── (main configuration files)
│       │
│       ├── ecr/                           # Private ECR repository with scan & lifecycle
│       │   └── (registry configuration)
│       │
│       ├── database/                      # MongoDB Atlas integration
│       │   └── (database configuration)
│       │
│       └── monitoring/                    # CloudWatch dashboards, alarms, log groups
│           └── (observability configuration)
│
├── scripts/
│   └── deploy-infrastructure.sh           # Local deployment helper (plan/apply/destroy)
│
├── monitoring/
│   ├── alarm-definitions.json             # 6 CloudWatch alarms
│   ├── cloudwatch-dashboard.json          # Dev dashboard configuration
│   └── log-insights-queries.txt           # 10 pre-built CloudWatch Logs Insights queries
│
├── ARCHITECTURE.md                        # System design, request flows, component details
├── RUNBOOK.md                             # Operations manual, incident response, troubleshooting
├── README.md                              # This file
├── .gitignore                             # Terraform state, SSH keys, .tfvars excluded
└── starttechimage.png                     # Architecture diagram

```

---

## Quick Start

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- AWS credentials configured with sufficient IAM permissions
- GitHub repository with Actions enabled

### 1. Clone & Setup

```bash
git clone https://github.com/lilsharkszn/starttech-infra.git
cd starttech-infra/terraform
```

### 2. Configure Variables

Create `terraform.tfvars` (not committed — use example):

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with your values
```

**Required variables:**
```hcl
aws_region           = "us-east-1"
environment          = "dev"
mongo_uri            = "mongodb+srv://user:pass@cluster.mongodb.net/?appName=App"
jwt_secret_key       = "your-64-char-hex-secret"
db_name              = "much_todo_db"
enable_cloudfront    = true  # Requires verified AWS account
```

### 3. Export Sensitive Variables (CI/CD or Local)

```bash
export TF_VAR_mongo_uri="mongodb+srv://user:pass@cluster.mongodb.net/?appName=App"
export TF_VAR_jwt_secret_key="$(openssl rand -hex 32)"
```

### 4. Deploy Infrastructure

**Via CI/CD (recommended):**
```bash
git push origin main
# → GitHub Actions runs: plan → manual approval → apply
```

**Locally:**
```bash
./scripts/deploy-infrastructure.sh plan    # Review changes
./scripts/deploy-infrastructure.sh apply   # Apply changes
./scripts/deploy-infrastructure.sh destroy # Destroy all (requires confirmation)
```

**Direct Terraform:**
```bash
terraform init
terraform plan
terraform apply
```

---

## Terraform Modules

### Module: `networking`

Provides the VPC and network foundation.

| Resource | Count | Configuration |
|---|---|---|
| VPC | 1 | 10.0.0.0/16 CIDR, DNS enabled |
| Public Subnets | 2 | 10.0.1.0/24, 10.0.2.0/24 (ALB, NAT) |
| Private App Subnets | 2 | 10.0.11.0/24, 10.0.12.0/24 (EC2) |
| Private Cache Subnets | 2 | 10.0.21.0/24, 10.0.22.0/24 (Redis) |
| Internet Gateway | 1 | Internet access for public subnets |
| NAT Gateway | 1 | Private subnet egress (single-AZ) |
| Route Tables | 3 | Public, private app, private cache |
| Security Groups | 3 | ALB, Backend, Redis with strict rules |

**Security Groups Chain:**
```
Internet (0.0.0.0/0)
    ↓ port 80/443
ALB Security Group
    ↓ port 8080 only
Backend Security Group (EC2)
    ↓ port 6379 only
Redis Security Group
```

### Module: `compute`

Hosts the backend application with auto-scaling and load balancing.

| Resource | Count | Configuration |
|---|---|---|
| Application Load Balancer | 1 | Public subnets, port 80/443 |
| Target Group | 1 | Health check on `/ping`, 5s interval |
| Launch Template | 1 | t3.micro, Ubuntu 22.04, user_data |
| Auto Scaling Group | 1 | Min 2, Max 4, warm-up 300s, rolling refresh |
| IAM Role | 1 | CloudWatch, ECR, SSM permissions |
| IAM Instance Profile | 1 | Attached to EC2 instances |

**User Data Includes:**
- Docker installation & systemd integration
- AWS CLI v2 setup
- CloudWatch Agent with custom metrics (CPU, memory, disk)
- ECR login credentials
- Application environment setup
- Container pull & startup

### Module: `storage`

Frontend asset hosting and CDN.

| Resource | Count | Configuration |
|---|---|---|
| S3 Bucket | 1 | dev-starttech-frontend-*, versioned, AES-256 encrypted |
| Bucket Policy | 1 | CloudFront OAC read-only access |
| CloudFront Distribution | 1 | When enabled, OAC origin, caching rules, HTTPS only |

**Caching Strategy:**
- HTML files: `no-cache` (always fetch fresh)
- JS/CSS/assets: `immutable, max-age=31536000` (1 year, Vite content-hashes)

### Module: `cache`

Redis session & response caching.

| Resource | Count | Configuration |
|---|---|---|
| ElastiCache Replication Group | 1 | Redis 7.0, Multi-AZ, 2 nodes (1 primary + 1 replica) |
| Subnet Group | 1 | Private cache subnets |
| Parameter Group | 1 | maxmemory-policy: allkeys-lru |
| Security Group Ingress | 1 | Backend → Redis port 6379 only |

**Features:**
- Automatic failover
- At-rest encryption
- TLS in-transit encryption
- Primary endpoint for reads/writes

### Module: `ecr`

Private container registry.

| Resource | Count | Configuration |
|---|---|---|
| ECR Repository | 1 | dev-starttech-backend, private, scan on push |
| Lifecycle Policy | 1 | Keep 10 most recent images |

### Module: `database`

MongoDB Atlas integration (external SaaS — no resources created).

| Property | Value |
|---|---|
| Cluster | cluster1.haej92u.mongodb.net |
| Collections | users, todos |
| Connection | TLS encrypted, MongoDB Atlas IP whitelist |

### Module: `monitoring`

CloudWatch observability.

| Resource | Count | Configuration |
|---|---|---|
| CloudWatch Log Group | 1 | /starttech/backend, 7-day retention |
| CloudWatch Alarms | 6 | ALB 5XX, Backend CPU, Unhealthy hosts, Redis CPU, ALB latency, ASG capacity |
| CloudWatch Dashboard | 1 | dev-starttech-dashboard with 10+ widgets |

**Alarms:**
| Alarm | Metric | Threshold | Action |
|---|---|---|---|
| dev-alb-5xx-errors | ALB 5XX count | > 10/min | Critical |
| dev-backend-high-cpu | EC2 CPU | > 80% | Warning |
| dev-backend-unhealthy-hosts | ALB unhealthy targets | > 0 | Critical |
| dev-redis-high-cpu | Redis CPU | > 75% | Warning |
| dev-alb-high-latency | ALB p99 latency | > 2s | Warning |
| dev-asg-min-capacity | ASG in-service | < 2 | Critical |

---

## CI/CD Pipeline

### Workflow: `infrastructure-deploy.yml`

Triggered on: push to main, pull request to main, manual dispatch

```
┌──────────────────────────────────────────────────────┐
│ Event: Push/PR/Manual Dispatch                       │
└──────────────────────────────────┬───────────────────┘
                                   │
                ┌──────────────────▼──────────────────┐
                │ JOB: terraform-plan                 │
                │ ─────────────────────────────────   │
                │ • Checkout repo                     │
                │ • Configure AWS credentials         │
                │ • terraform fmt -check              │
                │ • terraform init                    │
                │ • terraform validate                │
                │ • tfsec scan (HIGH severity)        │
                │ • terraform plan → artifact         │
                └──────────────────┬───────────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │ (main branch push only)   │ (manual: action=destroy) │
        ▼                           ▼                          ▼
    ┌─────────────┐        ┌──────────────┐        ┌──────────────┐
    │ terraform-  │        │ terraform-   │        │ terraform-   │
    │ apply       │        │ destroy      │        │ destroy      │
    │ ─────────   │        │ ──────────   │        │ ──────────   │
    │ • Needs     │        │ • Manual     │        │ • Confirm    │
    │   approval  │        │   approval   │        │   prompt     │
    │ • Download  │        │ • ECR login  │        │ • Destroy    │
    │   plan      │        │ • Apply plan │        │   -auto-ok   │
    │ • Apply     │        │              │        │              │
    │   -auto-ok  │        └──────────────┘        └──────────────┘
    └─────────────┘
```

**Required GitHub Secrets:**
- `AWS_ACCESS_KEY_ID` — AWS IAM access key
- `AWS_SECRET_ACCESS_KEY` — AWS IAM secret key
- `MONGO_URI` — MongoDB Atlas connection string
- `JWT_SECRET_KEY` — JWT signing secret (64-char hex)

**Required GitHub Environment:**
- Name: `production`
- Required reviewers: Your GitHub username (manual approval gate)

**Pipeline Stages:**

1. **terraform-plan** (all events)
   - Format validation
   - State initialization
   - Syntax validation
   - Security scan (tfsec, HIGH severity)
   - Generates plan artifact

2. **terraform-apply** (main branch push only + manual dispatch with action=apply)
   - Requires environment approval
   - Downloads plan artifact
   - Applies with `-auto-approve`

3. **terraform-destroy** (manual dispatch with action=destroy only)
   - Requires environment approval
   - Destroys all infrastructure
   - Prints summary on success

---

## Monitoring & Observability

### CloudWatch Logs

**Log Group:** `/starttech/backend`

**Streams per Instance:**
- `{instance-id}/app` — Application logs (JSON structured)
- `{instance-id}/error` — Error logs
- `{instance-id}/init` — Initialization logs

**Query Examples** (from `monitoring/log-insights-queries.txt`):
```
1. Errors in past 1 hour: fields @timestamp, @message | filter @message like /ERROR/ | stats count() by bin(5m)
2. Request latency p99: fields @duration | stats pct(@duration, 99) as p99
3. Top 10 slowest requests: fields @duration, @path | sort @duration desc | limit 10
4. Cache hit rate: fields @message | filter @message like /cache/ | stats count() as hits
5. Database connection errors: fields @message | filter @message like /mongo|connection/ | stats count()
... (and 5 more pre-built queries)
```

### CloudWatch Metrics

**Namespaces:**
- `AWS/ApplicationELB` — ALB request count, error rates, latency, target health
- `AWS/EC2` — Instance CPU, network in/out
- `AWS/ElastiCache` — Redis CPU, evictions, replication lag
- `AWS/AutoScaling` — ASG in-service count, desired capacity
- `StartTech/Backend` — Custom: CPU %, memory %, disk %

### CloudWatch Dashboard

**Name:** `dev-starttech-dashboard`

**Widgets:**
1. ALB Request Count (5-min aggregation)
2. ALB Error Rate (4XX, 5XX split)
3. ALB p99 Latency
4. Target Health (healthy vs unhealthy)
5. EC2 CPU Utilization (per instance)
6. EC2 Memory Utilization
7. Redis CPU Utilization
8. Redis Evictions (cache pressure)
9. ASG In-Service Count (desired vs actual)
10. Recent Error Log Tail

**Access:** AWS Console → CloudWatch → Dashboards → `dev-starttech-dashboard`

---

## Security

### Secrets Management

**Sensitive Variables:**
- `mongo_uri` — MongoDB Atlas connection string
- `jwt_secret_key` — JWT signing secret

**Storage:**
- ✅ Declared as `sensitive = true` in Terraform variables
- ✅ Passed via `TF_VAR_*` environment variables (CI/CD only)
- ✅ Never written to files
- ✅ `terraform.tfvars` is `.gitignore`'d

**GitHub Actions:**
- Secrets stored in GitHub organization/repository settings
- Injected at runtime, never logged
- Rotated independently from infrastructure

### Network Security

**Isolation:**
- EC2 instances in private subnets — **no direct internet access**
- ALB in public subnets — **only entry point for traffic**
- Backend security group accepts **only ALB → port 8080**
- Redis security group accepts **only Backend → port 6379**
- NAT Gateway enables private subnet egress for ECR pulls, MongoDB, AWS APIs

**SSH & Access:**
- SSH port 22 restricted to VPC CIDR (10.0.0.0/16)
- **Recommended:** Use AWS SSM Session Manager instead (no SSH needed)
- EC2 role grants `AmazonSSMManagedInstanceCore` permission

### IAM Least Privilege

**EC2 Instance Role Policies:**
- `CloudWatchAgentServerPolicy` — Ship logs/metrics to CloudWatch
- `AmazonEC2ContainerRegistryReadOnly` — Pull Docker images from ECR
- `AmazonSSMManagedInstanceCore` — SSM Session Manager access

### Data Encryption

- **S3 bucket:** AES-256 server-side encryption (at-rest)
- **Redis:** At-rest encryption + TLS in-transit (auth not required for private subnet)
- **ECR images:** Scan on push enabled (Trivy)
- **Terraform state:** S3 backend with AES-256 encryption + `use_lockfile = true`

### Scanning & Compliance

- **Terraform:** tfsec scan (HIGH severity minimum) in CI/CD
- **Container images:** Trivy scan on ECR push
- **IAM:** Least privilege enforced via module-scoped roles
- **Network:** Security groups restrict all traffic to specific ports/sources

---

## Operations & Troubleshooting

For comprehensive operational procedures, incident response guides, and troubleshooting, see **[RUNBOOK.md](RUNBOOK.md)**.

### Key Operational Commands

**View Infrastructure Status:**
```bash
# List backend instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev-backend-instance" \
  --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,State.Name]" \
  --output table

# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn <tg-arn> \
  --output table

# Check ASG status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names dev-backend-asg \
  --query "AutoScalingGroups[0].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,InService:Instances[?LifecycleState=='InService']|length(@)}" \
  --output table
```

**SSH/SSM Access to EC2 (Preferred):**
```bash
aws ssm start-session --target <instance-id>
# Inside session:
sudo docker ps
sudo docker logs muchtodo-backend --tail 50 -f
```

**Health Check:**
```bash
ALB="dev-backend-alb-xxxx.us-east-1.elb.amazonaws.com"
curl -s http://$ALB/ping
# Expected: {"message":"pong"}
```

**View Logs:**
```bash
# CloudWatch Logs Insights query
aws logs start-query \
  --log-group-name /starttech/backend \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | stats count() by bin(5m)'
```

**Scale Manually:**
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name dev-backend-asg \
  --desired-capacity 4
```

### Common Issues

| Issue | Cause | Solution |
|---|---|---|
| Container not starting | Wrong ECR image tag | Push image first, refresh ASG |
| /ping returns 502 | Container crashed | Check logs via SSM: `sudo docker logs muchtodo-backend` |
| Redis connection refused | TLS mismatch | Verify `REDIS_ADDR` uses `:6379` and `REDIS_TLS=true` |
| MongoDB auth failed | Rotated credentials | Update `MONGO_URI` secret, redeploy |
| ECR pull denied | IAM policy missing | Attach `AmazonEC2ContainerRegistryReadOnly` to EC2 role |
| Terraform state locked | Previous run crashed | Check S3 `.tflock` file, remove if stale |
| tfsec fails on HIGH severity | New security finding | Review, add to `.tfsecignore` if acceptable, fix otherwise |
| CloudFront returns 403 | Account not verified | Contact AWS Support — feature-flagged for verification |

---

## Outputs

After `terraform apply`, view key values:

```bash
terraform output

# Key outputs:
# alb_dns_name               = "dev-backend-alb-xxxx.us-east-1.elb.amazonaws.com"
# ecr_repository_url         = "xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/dev-starttech-backend"
# redis_endpoint             = "dev-starttech-redis-001.xxxxx.ng.0001.use1.cache.amazonaws.com"
# frontend_bucket_name       = "dev-starttech-frontend-jare-1"
# cloudfront_domain_name     = "dxxxxx.cloudfront.net"
# backend_log_group_name     = "/starttech/backend"
```

---

## Additional Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — System design, component details, request/deployment flows
- **[RUNBOOK.md](RUNBOOK.md)** — Operations manual, incident response, health checks, scaling, rollback procedures
- **[monitoring/](monitoring/)** — CloudWatch dashboard JSON, alarm definitions, Log Insights queries

---

## License

This project is part of StartTech. All rights reserved.

---

## Support

For issues, questions, or contributions, please refer to the [RUNBOOK.md](RUNBOOK.md) for operational procedures or open an issue in the GitHub repository.
