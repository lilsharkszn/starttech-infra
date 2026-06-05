# StartTech — System Architecture

![StartTech Architecture](starttechimage.png)

## Overview

StartTech is a full-stack Todo application deployed on AWS using a modern cloud-native architecture designed for high availability, automatic scaling, and operational observability.

## Quick Reference

| Component | Technology | Hosting |
|---|---|---|
| Frontend | React 18 + Vite + TypeScript | AWS S3 + CloudFront |
| Backend API | Go 1.23 + Gin | EC2 (ASG) behind ALB |
| Cache | Redis 7.0 | AWS ElastiCache Multi-AZ |
| Database | MongoDB | MongoDB Atlas |
| Container Registry | Docker | AWS ECR |
| Infrastructure | Terraform >= 1.10 | AWS us-east-1 |
| CI/CD | GitHub Actions | GitHub |
| Monitoring | CloudWatch | AWS us-east-1 |

## Network Layout

| Tier | CIDR | Resources |
|---|---|---|
| Public | 10.0.1.0/24, 10.0.2.0/24 | ALB, NAT Gateway |
| Private App | 10.0.11.0/24, 10.0.12.0/24 | EC2 instances (ASG) |
| Private Cache | 10.0.21.0/24, 10.0.22.0/24 | Redis cluster |

## Request Flow

### Frontend

User → CloudFront → S3 Bucket → index.html → React App React App → ALB → EC2 Backend → MongoDB Atlas / Redis


### Backend Deployment

GitHub Push → Actions: Test → Build → Trivy Scan → ECR Push → ASG Instance Refresh



### Frontend Deployment
GitHub Push → Actions: npm ci → npm audit → npm build → S3 Sync → CloudFront Invalidation


### Infrastructure Deployment
GitHub Push → Actions: fmt → validate → tfsec → plan → Manual Approval → apply



## Security Groups Chain
Internet (0.0.0.0/0) │ port 80/443 ▼ ALB Security Group │ port 8080 only ▼ Backend Security Group (EC2) │ port 6379 only ▼ Redis Security Group (ElastiCache)


## IAM Permissions — EC2 Role

| Policy | Purpose |
|---|---|
| CloudWatchAgentServerPolicy | Ship logs and metrics to CloudWatch |
| AmazonEC2ContainerRegistryReadOnly | Pull Docker images from ECR |
| AmazonSSMManagedInstanceCore | SSM Session Manager access (no SSH needed) |

## Monitoring Stack

| Layer | Tool | Details |
|---|---|---|
| Application logs | CloudWatch Logs | Log group: /starttech/backend |
| Infrastructure metrics | CloudWatch Metrics | EC2, ALB, Redis, ASG namespaces |
| Custom metrics | CloudWatch Agent | CPU, memory, disk per instance |
| Alerting | CloudWatch Alarms | 6 alarms across all tiers |
| Dashboard | CloudWatch Dashboard | dev-starttech-dashboard |
| Log analysis | Logs Insights | 10 pre-built queries |
