# Dynamically resolve registry URL — no hardcoded account ID
locals {
  ecr_registry = split("/", var.ecr_repository_url)[0]
}

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.environment}-backend-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [
    var.backend_security_group_id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -xe

# ── System update & dependencies ──────────────────────────
apt-get update -y
apt-get install -y docker.io git jq curl unzip wget

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

mkdir -p /opt/starttech
mkdir -p /var/log/starttech

# ── AWS CLI v2 ─────────────────────────────────────────────
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
cd /tmp && unzip -o awscliv2.zip
/tmp/aws/install
aws --version

# ── CloudWatch Agent ───────────────────────────────────────
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
  -O /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb

# CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/starttech/app.log",
            "log_group_name": "/starttech/backend",
            "log_stream_name": "{instance_id}/app",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S"
          },
          {
            "file_path": "/var/log/starttech/error.log",
            "log_group_name": "/starttech/backend",
            "log_stream_name": "{instance_id}/error",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S"
          },
          {
            "file_path": "/var/log/starttech-init.log",
            "log_group_name": "/starttech/backend",
            "log_stream_name": "{instance_id}/init"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "StartTech/Backend",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "resources": ["/"],
        "metrics_collection_interval": 60
      }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# ── ECR Login (dynamic registry, no hardcoded account ID) ──
ECR_REGISTRY="${local.ecr_registry}"
aws ecr get-login-password --region ${var.aws_region} | docker login \
  --username AWS \
  --password-stdin "$ECR_REGISTRY"

# ── Application environment ────────────────────────────────
cat > /opt/starttech/.env << ENV
PORT=8080
MONGO_URI=${var.mongo_uri}
DB_NAME=${var.db_name}
JWT_SECRET_KEY=${var.jwt_secret_key}
REDIS_ADDR=${var.redis_endpoint}:6379
REDIS_PASSWORD=
ENABLE_CACHE=true
LOG_LEVEL=info
LOG_FORMAT=json
ENV

# ── Pull & run application ─────────────────────────────────
docker pull ${var.ecr_repository_url}:latest

docker rm -f muchtodo-backend || true

docker run -d \
  --name muchtodo-backend \
  --restart unless-stopped \
  --env-file /opt/starttech/.env \
  -p 8080:8080 \
  --log-driver json-file \
  --log-opt max-size=50m \
  --log-opt max-file=3 \
  ${var.ecr_repository_url}:latest

# ── Verify container started ───────────────────────────────
sleep 10
if docker ps | grep -q muchtodo-backend; then
  echo "$(date -Iseconds) [INFO] StartTech backend launched successfully" >> /var/log/starttech/init.log
else
  echo "$(date -Iseconds) [ERROR] Container failed to start" >> /var/log/starttech/init.log
  docker logs muchtodo-backend >> /var/log/starttech/error.log 2>&1
  exit 1
fi
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-backend-instance"
    }
  }
}
