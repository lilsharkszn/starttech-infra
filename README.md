# StartTech Infrastructure

Infrastructure as Code for the StartTech full-stack application, managed with Terraform and deployed via GitHub Actions CI/CD.

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Terraform Modules](#terraform-modules)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring](#monitoring)
- [Security](#security)

---

## Architecture Overview

![StartTech Architecture](starttechimage.png)
Internet │ ▼ [CloudFront CDN] ──── [S3 Frontend Bucket] │ ▼ [Application Load Balancer] (Public Subnets) │ ▼ [Auto Scaling Group] (Private App Subnets) EC2 × 2–4 instances Docker: muchtodo-backend │ │ ▼ ▼ [MongoDB [ElastiCache Redis] Atlas] (Private Cache Subnets)


**Region:** us-east-1
**Environment:** dev
**State Backend:** S3 + native locking

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10.0
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- AWS credentials with sufficient IAM permissions
- GitHub repository with Actions enabled

---

## Repository Structure
starttech-infra/ ├── .github/ │ └── workflows/ │ └── infrastructure-deploy.yml # Terraform CI/CD pipeline ├── terraform/ │ ├── backend.tf # S3 remote state config │ ├── main.tf # Root module — wires all modules │ ├── variables.tf # Input variable declarations │ ├── outputs.tf # Root outputs │ ├── providers.tf # AWS provider config │ ├── versions.tf # Terraform + provider versions │ ├── terraform.tfvars.example # Variable template (safe to commit) │ └── modules/ │ ├── networking/ # VPC, subnets, security groups, NAT │ ├── compute/ # ALB, ASG, launch template, IAM │ ├── storage/ # S3 bucket, CloudFront distribution │ ├── cache/ # ElastiCache Redis cluster │ ├── ecr/ # Elastic Container Registry │ └── monitoring/ # CloudWatch logs, alarms, dashboard ├── monitoring/ │ ├── cloudwatch-dashboard.json # Dashboard widget definitions │ ├── alarm-definitions.json # Alarm reference definitions │ └── log-insights-queries.txt # Pre-built Logs Insights queries ├── scripts/ │ └── deploy-infrastructure.sh # Manual deployment helper └── README.md


---

## Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_ORG/starttech-infra.git
cd starttech-infra/terraform

2. Configure variables

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values — never commit this file
3. Export sensitive variablesexport TF_VAR_mongo_uri="mongodb+srv://user:pass@cluster.mongodb.net/?appName=App"
export TF_VAR_jwt_secret_key="$(openssl rand -hex 32)"
4. Deploy
terraform init
terraform plan
terraform apply
5. Or use the helper script
# Plan only
./scripts/deploy-infrastructure.sh plan

# Apply
./scripts/deploy-infrastructure.sh apply
Terraform Modules
ModuleDescriptionKey Resources
networkingNetwork foundationVPC, public/private subnets, IGW, NAT, route tables, security groups
computeApplication hostingALB, target group, ASG, launch template, IAM roles, CloudWatch agent
storageFrontend hostingS3 bucket (versioned, encrypted), CloudFront OAC distribution
cacheSession & cachingElastiCache Redis 7.0, multi-AZ, at-rest + in-transit encryption
ecrContainer registryPrivate ECR repository, scan on push, lifecycle policy (keep 10)
monitoring/ObservabilityCloudWatch log group, metric alarms, dashboard
Subnet Layout
TierCIDRPurpose
Public10.0.1.0/24, 10.0.2.0/24ALB, NAT Gateway
Private App10.0.11.0/24, 10.0.12.0/24EC2 instances
Private Cache10.0.21.0/24, 10.0.22.0/24Redis cluster
CI/CD Pipeline
The GitHub Actions workflow (.github/workflows/infrastructure-deploy.yml) runs automatically on push/PR to main.
Pipeline Stages
Text

Unwrap

Copy
PR / Push to main
      │
      ▼
┌─────────────────────┐
│  terraform-plan     │
│  ─────────────────  │
│  • fmt check        │
│  • init             │
│  • validate         │
│  • tfsec scan       │
│  • plan → artifact  │
└─────────────────────┘
      │ (main branch push only)
      ▼
┌─────────────────────┐
│  terraform-apply    │
│  ─────────────────  │
│  • manual approval  │  ← GitHub Environment gate
│  • download plan    │
│  • apply            │
└─────────────────────┘
Required GitHub Secrets
SecretDescription
AWS_ACCESS_KEY_IDAWS IAM access key
AWS_SECRET_ACCESS_KEYAWS IAM secret key
MONGO_URIMongoDB Atlas connection string
JWT_SECRET_KEYJWT signing secret (64-char hex)
Required GitHub Environment
Environment name: production
Required reviewer: your GitHub username (manual approval gate before apply)
Monitoring
CloudWatch Dashboard
Navigate to: AWS Console → CloudWatch → Dashboards → dev-starttech-dashboard
Dashboard includes:
Backend EC2 CPU & memory utilization
ALB request count, error rates (4xx/5xx), p99 latency
ALB healthy vs unhealthy host count
Redis CPU utilization and cache hit rate
ASG in-service instance count
Live error log tail
Alarms
AlarmMetricThreshold
dev-alb-5xx-errorsALB 5XX count> 10 per minute
dev-backend-high-cpuEC2 CPU> 80%
dev-backend-unhealthy-hostsALB unhealthy targets> 0
dev-redis-high-cpuRedis CPU> 75%
dev-alb-high-latencyALB p99 latency> 2s
dev-asg-min-capacityASG in-service count< 2
Log Insights
Pre-built queries are in monitoring/log-insights-queries.txt. Navigate to: CloudWatch → Logs Insights → select /starttech/backend
Security
Secrets Management
All sensitive values (mongo_uri, jwt_secret_key) declared as sensitive = true in Terraform
Passed via TF_VAR_ environment variables in CI/CD — never written to files
terraform.tfvars is git-ignored — only terraform.tfvars.example is committed
Network Security
EC2 instances in private subnets — no direct internet access
ALB in public subnets — only entry point for HTTP/HTTPS traffic
Backend security group: only accepts traffic from ALB security group on port 8080
Redis security group: only accepts traffic from backend security group on port 6379
SSH restricted to VPC CIDR (10.0.0.0/16) — use SSM Session Manager instead
IAM — Least Privilege
EC2 instances are granted only:
CloudWatchAgentServerPolicy — ship logs/metrics
AmazonEC2ContainerRegistryReadOnly — pull images from ECR
AmazonSSMManagedInstanceCore — SSM access (no SSH needed)
Data Encryption
S3 bucket: AES-256 server-side encryption
Redis: at-rest encryption + TLS in transit
ECR: image scanning on push enabled EOF

---

### 📄 `starttech-infra/ARCHITECTURE.md`
```bash
cat > ARCHITECTURE.md << 'EOF'
# StartTech — System Architecture

## Overview

StartTech is a full-stack Todo application deployed on AWS using a modern cloud-native architecture. The system is designed for high availability, automatic scaling, and operational observability.

---

## Architecture Diagram
┌─────────────────────────────────────────────────────────────────┐ │ INTERNET │ └───────────────────────┬─────────────────┬───────────────────────┘ │ │ ▼ ▼ ┌─────────────────┐ ┌─────────────────┐ │ CloudFront CDN │ │ GitHub Actions │ │ (us-east-1) │ │ CI/CD Runner │ └────────┬────────┘ └────────┬────────┘ │ │ ▼ ▼ ┌─────────────────┐ ┌─────────────────┐ │ S3 Bucket │ │ ECR Repository │ │ (Frontend) │ │ (Docker Images) │ └─────────────────┘ └────────┬────────┘ │ ┌───────────────────────────────────────────┼───────────────────┐ │ VPC: 10.0.0.0/16 AWS │ │ │ ▼ │ │ ┌──────────────────────────────────────────────────────┐ │ │ │ Public Subnets (us-east-1a/1b) │ │ │ │ 10.0.1.0/24 │ 10.0.2.0/24 │ │ │ │ │ │ │ │ ┌──────────────────────────┐ ┌─────────────────┐ │ │ │ │ │ Application Load │ │ NAT Gateway │ │ │ │ │ │ Balancer (HTTP:80) │ │ (Elastic IP) │ │ │ │ │ └──────────┬───────────────┘ └─────────────────┘ │ │ │ └─────────────┼────────────────────────────────────────┘ │ │ │ │ │ ┌─────────────┼────────────────────────────────────────┐ │ │ │ Private App Subnets (us-east-1a/1b) │ │ │ │ 10.0.11.0/24 │ 10.0.12.0/24 │ │ │ │ │ │ │ │ ┌─────────────────────────────────────────────┐ │ │ │ │ │ Auto Scaling Group (min:2, max:4) │ │ │ │ │ │ │ │ │ │ │ │ ┌───────────────┐ ┌───────────────┐ │ │ │ │ │ │ │ EC2 (t3.micro│ │ EC2 (t3.micro│ │ │ │ │ │ │ │ Docker: │ │ Docker: │ │ │ │ │ │ │ │ muchtodo-back │ │ muchtodo-back│ │ │ │ │ │ │ │ :8080 │ │ :8080 │ │ │ │ │ │ │ │ CW Agent │ │ CW Agent │ │ │ │ │ │ │ └───────┬────────┘ └───────┬───────┘ │ │ │ │ │ └──────────┼───────────────────┼───────────────┘ │ │ │ └─────────────┼───────────────────┼────────────────────┘ │ │ │ │ │ │ ┌─────────────┼───────────────────┼────────────────────┐ │ │ │ Private Cache Subnets │ │ │ │ │ 10.0.21.0/24 │ 10.0.22.0/24 │ │ │ │ │ ▼ │ │ │ │ ┌──────────────────────────────────────────────┐ │ │ │ │ │ ElastiCache Redis 7.0 (Multi-AZ) │ │ │ │ │ │ Primary: us-east-1a Replica: us-east-1b │ │ │ │ │ │ TLS enabled │ At-rest encrypted │ │ │ │ │ └──────────────────────────────────────────────┘ │ │ │ └──────────────────────────────────────────────────────┘ │ └───────────────────────────────────────────────────────────────┘ │ ▼ ┌─────────────────────┐ │ MongoDB Atlas │ │ (External SaaS) │ │ cluster1.haej92u │ └─────────────────────┘
         ┌─────────────────────┐
         │   CloudWatch        │
         │   Logs / Metrics /  │
         │   Alarms / Dashboard│
         └─────────────────────┘

---

## Component Details

### Frontend — React (Vite + TypeScript)
| Property | Value |
|---|---|
| Framework | React 18 + TanStack Router |
| Build tool | Vite |
| Hosting | AWS S3 (static website) |
| CDN | AWS CloudFront (when account verified) |
| State | S3 bucket: `dev-starttech-frontend-jare-1` |

**Request flow:**
User → CloudFront → S3 bucket → index.html User → React app → API calls → ALB → Backend

### Backend — Golang API
| Property | Value |
|---|---|
| Language | Go 1.23 |
| Framework | Gin |
| Containerised | Yes — Docker |
| Registry | AWS ECR |
| Hosting | EC2 in ASG behind ALB |
| Port | 8080 |
| Health endpoint | `GET /ping` |

**Key features:**
- JWT authentication (cookie + Authorization header)
- Redis-backed username cache
- Structured JSON logging → CloudWatch
- Graceful shutdown on SIGTERM

### Database — MongoDB Atlas
| Property | Value |
|---|---|
| Type | MongoDB Atlas (external SaaS) |
| Cluster | cluster1.haej92u.mongodb.net |
| Connection | TLS encrypted connection string |
| Collections | `users`, `todos` |

### Cache — AWS ElastiCache Redis
| Property | Value |
|---|---|
| Engine | Redis 7.0 |
| Node type | cache.t3.micro |
| Topology | Multi-AZ replication group |
| Nodes | 2 (1 primary + 1 replica) |
| Failover | Automatic |
| Encryption | At-rest + TLS in transit |
| Use case | Username existence cache, sessions |

---

## Network Security Groups
Internet → ALB SG (port 80, 443) ALB SG → Backend SG (port 8080 only) Backend SG → Redis SG (port 6379 only) Backend SG → NAT → Internet (ECR pull, MongoDB Atlas, AWS APIs)

---

## CI/CD Architecture
Developer push to main │ ▼ GitHub Actions │ ┌─────┴──────┐ │ │ ▼ ▼ Backend Frontend Pipeline Pipeline │ │ ├─ Test ├─ npm ci ├─ Build ├─ npm audit ├─ Trivy ├─ npm build ├─ ECR push ├─ S3 sync └─ ASG └─ CF invalidate refresh

### Deployment Strategy — Backend
Rolling instance refresh via ASG:
- **MinHealthyPercentage:** 50% — ensures at least 1 instance stays live
- **InstanceWarmup:** 300s — new instance gets time to pull image and start
- New instances pull `:latest` image from ECR on boot via `user_data`

### Deployment Strategy — Frontend
Two-phase S3 sync with split cache headers:
- **HTML files** — `no-cache` (browser always fetches fresh)
- **JS/CSS/assets** — `immutable, max-age=31536000` (1 year — Vite content-hashes filenames)

---

## Infrastructure State Management

| Property | Value |
|---|---|
| Backend | AWS S3 |
| Bucket | `adejare-starttech-tf-state` |
| Key | `global/terraform.tfstate` |
| Encryption | AES-256 |
| Locking | S3 native locking (`use_lockfile = true`) |

---

## Observability

| Layer | Tool | Details |
|---|---|---|
| Application logs | CloudWatch Logs | Log group: `/starttech/backend` |
| Infrastructure metrics | CloudWatch Metrics | EC2, ALB, Redis, ASG namespaces |
| Custom metrics | CloudWatch Agent | CPU, memory, disk per instance |
| Alerting | CloudWatch Alarms | 6 alarms across all tiers |
| Dashboard | CloudWatch Dashboard | `dev-starttech-dashboard` |
| Log analysis | Logs Insights | 10 pre-built queries |
