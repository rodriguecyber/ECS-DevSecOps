# Secure CI/CD Pipeline - Implementation Guide

## Project Overview

This project implements a **hardened CI/CD pipeline** for a containerized Node.js application with comprehensive security scanning and deployment to Amazon ECS (Fargate).

---

## ✅ Feature Implementation Checklist    

| Requirement | Implemented | Location | Tool Used |
|-------------|-------------|----------|-----------|
| SAST (Static Analysis) | ✅ | `Jenkinsfile` - Stage: "SAST (SonarQube)" | SonarQube |
| SCA (Dependency Scan) | ✅ | `Jenkinsfile` - Stage: "SCA (Snyk)" | Snyk |
| Container Image Scan | ✅ | `Jenkinsfile` - Stage: "Trivy Scan" | Trivy |
| Secret Scanning | ✅ | `Jenkinsfile` - Stage: "Secret Scan (Gitleaks)" | Gitleaks |
| SBOM Generation | ✅ | `Jenkinsfile` - Stage: "SBOM (Syft)" | Syft (SPDX + CycloneDX) |
| Security Gates | ✅ | `Jenkinsfile` - Stages: "Security Gate", "Container Gate" | Custom Logic |
| ECR Image Push | ✅ | `Jenkinsfile` - Stage: "Push to ECR" | AWS CLI |
| ECS Task Definition | ✅ | `Jenkinsfile` - Stage: "Deploy to ECS" | AWS CLI |
| ECS Service Update | ✅ | `Jenkinsfile` - Stage: "Deploy to ECS" | Rolling Update |
| CloudWatch Logs | ✅ | Task Definition - `logConfiguration` | awslogs driver |
| ECR Lifecycle | ✅ | `terraform/modules/ecr/main.tf` | Lifecycle Policy |
| Infrastructure as Code | ✅ | `terraform/` | Terraform (Modular) |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SECURE CI/CD PIPELINE                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────┐     ┌─────────────────────────────────────────────────┐  │
│   │  GitHub  │────▶│                   JENKINS                       │  │
│   │   Push   │     │                                                 │  │
│   └──────────┘     │  ┌─────────────────────────────────────────┐   │  │
│                    │  │         SECURITY SCANS (Parallel)        │   │  │
│                    │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐    │   │  │
│                    │  │  │Gitleaks │ │SonarQube│ │  Snyk   │    │   │  │
│                    │  │  │(Secrets)│ │ (SAST)  │ │ (SCA)   │    │   │  │
│                    │  │  └────┬────┘ └────┬────┘ └────┬────┘    │   │  │
│                    │  └───────┼──────────┼──────────┼───────────┘   │  │
│                    │          └──────────┼──────────┘               │  │
│                    │                     ▼                          │  │
│                    │          ┌─────────────────────┐               │  │
│                    │          │   SECURITY GATE     │               │  │
│                    │          │ (Block on Critical) │               │  │
│                    │          └──────────┬──────────┘               │  │
│                    │                     │ PASS                     │  │
│                    │                     ▼                          │  │
│                    │          ┌─────────────────────┐               │  │
│                    │          │    DOCKER BUILD     │               │  │
│                    │          └──────────┬──────────┘               │  │
│                    │                     ▼                          │  │
│                    │  ┌─────────────────────────────────────────┐   │  │
│                    │  │      CONTAINER SECURITY (Parallel)       │   │  │
│                    │  │  ┌─────────────┐    ┌─────────────┐     │   │  │
│                    │  │  │   Trivy     │    │    Syft     │     │   │  │
│                    │  │  │ (Vuln Scan) │    │   (SBOM)    │     │   │  │
│                    │  │  └──────┬──────┘    └─────────────┘     │   │  │
│                    │  └─────────┼───────────────────────────────┘   │  │
│                    │            ▼                                   │  │
│                    │  ┌─────────────────────┐                       │  │
│                    │  │  CONTAINER GATE     │                       │  │
│                    │  └──────────┬──────────┘                       │  │
│                    │             │ PASS                             │  │
│                    └─────────────┼──────────────────────────────────┘  │
│                                  ▼                                     │
│   ┌──────────────────────────────────────────────────────────────────┐ │
│   │                         AWS CLOUD                                 │ │
│   │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌──────────────┐  │ │
│   │  │   ECR   │───▶│   ECS   │───▶│   ALB   │───▶│  CloudWatch  │  │ │
│   │  │ (Image) │    │(Fargate)│    │         │    │(Logs/Alarms) │  │ │
│   │  └─────────┘    └─────────┘    └─────────┘    └──────────────┘  │ │
│   └──────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
.
├── Jenkinsfile                 # CI/CD Pipeline (all security scans + ECS deployment)
├── Dockerfile                  # Multi-stage secure Docker build
├── sonar-project.properties    # SonarQube configuration
├── .gitleaks.toml              # Gitleaks secret detection rules
├── .snyk                       # Snyk policy configuration
├── trivy.yaml                  # Trivy scanner configuration
├── .trivyignore                # Trivy ignore rules
├── terraform/                  # Infrastructure as Code
│   ├── modules/
│   │   ├── vpc/                # VPC, Subnets, NAT Gateway
│   │   ├── ecr/                # Container Registry + Lifecycle Policy
│   │   ├── alb/                # Application Load Balancer
│   │   ├── iam/                # ECS Task Roles
│   │   └── ecs/                # ECS Cluster, Service, Auto-scaling, Alarms
│   └── environments/
│       ├── dev/                # Development environment
│       └── prod/               # Production environment
├── app.js                      # Application code
├── routes/                     # API routes
├── models/                     # Data models
└── tests/                      # Test suites
```

---

## 🔒 Security Tools Implementation

### 1. Secret Scanning (Gitleaks)

**File:** `Jenkinsfile` - Line 57-62

```groovy
stage('Secret Scan (Gitleaks)') {
    steps {
        script {
            def result = sh(script: "gitleaks detect --source . --report-format json --report-path ${REPORTS_DIR}/gitleaks.json --exit-code 1", returnStatus: true)
            env.SECRETS_FOUND = result != 0 ? 'true' : 'false'
        }
    }
}
```

**Purpose:** Detects hardcoded secrets, API keys, passwords in source code  
**Output:** `security-reports/gitleaks.json`  
**Gate:** Blocks pipeline if secrets found

---

### 2. SAST - SonarQube

**File:** `Jenkinsfile` - Line 63-68

```groovy
stage('SAST (SonarQube)') {
    steps {
        withSonarQubeEnv('SonarQube') {
            sh "sonar-scanner -Dsonar.projectKey=secure-webapp -Dsonar.projectVersion=${IMAGE_TAG}"
        }
    }
}
```

**Configuration:** `sonar-project.properties`
```properties
sonar.projectKey=secure-webapp
sonar.sources=.
sonar.exclusions=node_modules/**,coverage/**
sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

**Purpose:** Static code analysis for bugs, code smells, security vulnerabilities  
**Gate:** Quality Gate in "Quality Gate" stage (Line 88-95)

---

### 3. SCA - Snyk

**File:** `Jenkinsfile` - Line 69-76

```groovy
stage('SCA (Snyk)') {
    steps {
        script {
            sh "snyk auth ${SNYK_TOKEN}"
            def result = sh(script: "snyk test --json > ${REPORTS_DIR}/snyk.json --severity-threshold=high", returnStatus: true)
            env.SCA_VULNERABILITIES = result != 0 ? 'true' : 'false'
        }
    }
}
```

**Purpose:** Scans dependencies for known vulnerabilities (CVEs)  
**Output:** `security-reports/snyk.json`  
**Gate:** Blocks if High/Critical vulnerabilities found

---

### 4. Container Image Scan - Trivy

**File:** `Jenkinsfile` - Line 124-132

```groovy
stage('Trivy Scan') {
    steps {
        script {
            sh "trivy image --format json -o ${REPORTS_DIR}/trivy.json ${ECR_IMAGE}:${IMAGE_TAG} || true"
            def result = sh(script: "trivy image --exit-code 1 --severity CRITICAL,HIGH ${ECR_IMAGE}:${IMAGE_TAG}", returnStatus: true)
            env.IMAGE_VULNERABILITIES = result != 0 ? 'true' : 'false'
        }
    }
}
```

**Configuration:** `trivy.yaml`  
**Purpose:** Scans container image for OS and library vulnerabilities  
**Output:** `security-reports/trivy.json`  
**Gate:** Blocks if Critical/High vulnerabilities in image

---

### 5. SBOM Generation - Syft

**File:** `Jenkinsfile` - Line 133-139

```groovy
stage('SBOM (Syft)') {
    steps {
        sh """
            syft ${ECR_IMAGE}:${IMAGE_TAG} -o spdx-json > ${SBOM_DIR}/sbom-spdx.json
            syft ${ECR_IMAGE}:${IMAGE_TAG} -o cyclonedx-json > ${SBOM_DIR}/sbom-cyclonedx.json
        """
    }
}
```

**Purpose:** Generates Software Bill of Materials for compliance  
**Output:** 
- `sbom/sbom-spdx.json` (SPDX format)
- `sbom/sbom-cyclonedx.json` (CycloneDX format)

---

## 🚦 Security Gates

### Pre-Build Security Gate

**File:** `Jenkinsfile` - Line 97-107

```groovy
stage('Security Gate') {
    steps {
        script {
            def failures = []
            if (env.SECRETS_FOUND == 'true') failures.add("Secrets detected")
            if (env.SCA_VULNERABILITIES == 'true') failures.add("High/Critical vulnerabilities")
            if (env.SONAR_GATE_FAILED == 'true') failures.add("Quality gate failed")
            
            if (failures.size() > 0 && !params.SKIP_SECURITY_GATES) {
                error("Security Gate FAILED: ${failures.join(', ')}")
            }
        }
    }
}
```

### Post-Build Container Gate

**File:** `Jenkinsfile` - Line 142-148

```groovy
stage('Container Gate') {
    steps {
        script {
            if (env.IMAGE_VULNERABILITIES == 'true' && !params.SKIP_SECURITY_GATES) {
                error("Container Security Gate FAILED: Critical/High vulnerabilities in image")
            }
        }
    }
}
```

---

## 🚀 AWS Deployment

### ECR Image Push

**File:** `Jenkinsfile` - Line 150-156

```groovy
stage('Push to ECR') {
    steps {
        sh """
            aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
            docker push ${ECR_IMAGE}:${IMAGE_TAG}
            docker push ${ECR_IMAGE}:latest
        """
    }
}
```

### ECS Task Definition & Deployment

**File:** `Jenkinsfile` - Line 158-208

Key features:
- **Fargate** launch type
- **CloudWatch Logs** via awslogs driver
- **Health Check** configured
- **Rolling deployment** via `update-service --force-new-deployment`

```groovy
"logConfiguration": {
    "logDriver": "awslogs",
    "options": {
        "awslogs-group": "/ecs/${params.ECS_SERVICE}",
        "awslogs-region": "${params.AWS_REGION}",
        "awslogs-stream-prefix": "ecs",
        "awslogs-create-group": "true"
    }
}
```

---

## 🏗️ Infrastructure (Terraform)

### Module Structure

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `vpc` | Networking | VPC, Subnets, NAT, IGW |
| `ecr` | Container Registry | ECR Repo, Lifecycle Policy |
| `alb` | Load Balancing | ALB, Target Groups, Listeners |
| `iam` | Security | Task Execution Role, Task Role |
| `ecs` | Compute | Cluster, Service, Task Def, Auto-scaling, Alarms |

### ECR Lifecycle Policy

**File:** `terraform/modules/ecr/main.tf`

```hcl
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.image_count
      }
      action = { type = "expire" }
    }]
  })
}
```

### CloudWatch Alarms

**File:** `terraform/modules/ecs/main.tf`

```hcl
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  ...
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.name}-memory-high"
  threshold           = 80
  metric_name         = "MemoryUtilization"
  ...
}
```

---

## 📊 Pipeline Flow

```
1. CHECKOUT
      │
      ▼
2. INSTALL DEPENDENCIES (npm ci)
      │
      ▼
3. SECURITY SCANS (Parallel)
   ├── Gitleaks (Secrets) ──────┐
   ├── SonarQube (SAST) ────────┼──▶ Reports Generated
   └── Snyk (SCA) ──────────────┘
      │
      ▼
4. UNIT TESTS (npm test --coverage)
      │
      ▼
5. QUALITY GATE (SonarQube)
      │
      ▼
6. SECURITY GATE ◄─── FAIL if secrets/vulnerabilities found
      │
      ▼ PASS
7. DOCKER BUILD (Multi-stage)
      │
      ▼
8. CONTAINER SECURITY (Parallel)
   ├── Trivy (Image Scan) ──────┬──▶ Reports Generated
   └── Syft (SBOM) ─────────────┘
      │
      ▼
9. CONTAINER GATE ◄─── FAIL if image vulnerabilities found
      │
      ▼ PASS
10. PUSH TO ECR
      │
      ▼
11. REGISTER ECS TASK DEFINITION
      │
      ▼
12. UPDATE ECS SERVICE (Rolling Deployment)
      │
      ▼
13. WAIT FOR STABLE
      │
      ▼
14. CLEANUP (Local images)
      │
      ▼
15. ARCHIVE REPORTS (security-reports/*, sbom/*)
```

---

## 🧪 Testing Security Gates

### Inject Vulnerable Dependency

Add to `package.json`:
```json
"dependencies": {
    "lodash": "4.17.15"
}
```

This version has known CVEs:
- CVE-2020-8203
- CVE-2021-23337

**Expected Result:** Pipeline fails at "Security Gate" stage

### Fix Vulnerability

Update to safe version:
```json
"dependencies": {
    "lodash": "4.17.21"
}
```

**Expected Result:** Pipeline passes and deploys to ECS

---

## 📋 Deliverables Summary

| Deliverable | Location |
|-------------|----------|
| CI Pipeline Config | `Jenkinsfile` |
| ECS Task Definition | Generated in pipeline (`task-definition.json`) |
| Security Reports | `security-reports/` (archived in Jenkins) |
| SBOM Files | `sbom/sbom-spdx.json`, `sbom/sbom-cyclonedx.json` |
| Infrastructure | `terraform/` |
| Documentation | `IMPLEMENTATION.md` (this file) |

---

## 🔧 Required Jenkins Credentials

| Credential ID | Type | Description |
|---------------|------|-------------|
| `aws-credentials` | Username/Password | AWS Access Key / Secret Key |
| `sonarqube-url` | Secret Text | SonarQube server URL |
| `sonarqube-token` | Secret Text | SonarQube auth token |
| `snyk-token` | Secret Text | Snyk API token |

---

## 🚀 Deployment Commands

### Deploy Infrastructure (Terraform)

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Trigger Pipeline (Jenkins)

Configure parameters:
- `AWS_ACCOUNT_ID`: Your AWS account ID
- `AWS_REGION`: Target region (e.g., `us-east-1`)
- `ECR_REPOSITORY`: `secure-webapp`
- `ECS_CLUSTER`: From Terraform output
- `ECS_SERVICE`: From Terraform output
