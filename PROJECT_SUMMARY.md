# Secure CI/CD Pipeline - Project Summary

## Lab Objective

Build a **security-hardened CI/CD pipeline** that:
1. Scans code for vulnerabilities before deployment
2. Blocks deployment when critical issues found
3. Deploys securely to AWS ECS Fargate
4. Generates compliance artifacts (SBOM)

---

## What Was Implemented

### 1. Security Scanning Tools (5 Tools)

| Tool | Type | What It Does | Pipeline Stage |
|------|------|--------------|----------------|
| **Gitleaks** | Secret Scanning | Finds hardcoded API keys, passwords, tokens | `Secret Scan (Gitleaks)` |
| **SonarQube** | SAST | Static code analysis - bugs, code smells, security issues | `SAST (SonarQube)` |
| **Snyk** | SCA | Scans `package.json` dependencies for CVEs | `SCA (Snyk)` |
| **Trivy** | Container Scan | Scans Docker image for OS/library vulnerabilities | `Trivy Scan` |
| **Syft** | SBOM | Generates Software Bill of Materials | `SBOM (Syft)` |

### 2. Security Gates (2 Gates)

| Gate | When | Blocks If |
|------|------|-----------|
| **Security Gate** | After code scans | Secrets found, High/Critical CVEs, Quality gate failed |
| **Container Gate** | After image scan | High/Critical vulnerabilities in Docker image |

### 3. Deployment (AWS ECS Fargate)

| Component | Purpose |
|-----------|---------|
| **ECR** | Container image registry with lifecycle policy |
| **ECS Cluster** | Fargate compute for running containers |
| **ECS Service** | Manages task deployment with rolling updates |
| **ALB** | Load balancer with health checks |
| **CloudWatch** | Centralized logging + CPU/Memory alarms |

---

## Key Files

| File | Purpose |
|------|---------|
| `Jenkinsfile` | Main CI/CD pipeline (258 lines) |
| `Dockerfile` | Multi-stage secure container build |
| `sonar-project.properties` | SonarQube project config |
| `.gitleaks.toml` | Custom secret detection rules |
| `trivy.yaml` | Container scan severity settings |
| `.snyk` | Snyk vulnerability policy |
| `terraform/` | Infrastructure as Code (modular) |

---

## Pipeline Flow

```
1. Checkout Code
       │
2. Install Dependencies (npm ci)
       │
3. Security Scans (PARALLEL)
   ├── Gitleaks → secrets found?
   ├── SonarQube → code issues?
   └── Snyk → vulnerable deps?
       │
4. Unit Tests (npm test)
       │
5. Quality Gate (SonarQube)
       │
6. ❌ SECURITY GATE → FAIL if issues found
       │ ✅ PASS
7. Docker Build
       │
8. Container Security (PARALLEL)
   ├── Trivy → image vulnerabilities?
   └── Syft → generate SBOM
       │
9. ❌ CONTAINER GATE → FAIL if image issues
       │ ✅ PASS
10. Push to ECR
       │
11. Register ECS Task Definition
       │
12. Update ECS Service (Rolling Deploy)
       │
13. Archive Reports
```

---

## Terraform Modules

```
terraform/
├── modules/
│   ├── vpc/    → VPC, subnets, NAT gateway
│   ├── ecr/    → Container registry + lifecycle
│   ├── alb/    → Load balancer + health checks
│   ├── iam/    → ECS execution/task roles
│   └── ecs/    → Cluster, service, auto-scaling, alarms
└── environments/
    ├── dev/    → Cost-optimized (no NAT)
    └── prod/   → High availability (NAT enabled)
```

---

## Reports Generated

| Report | Format | Location |
|--------|--------|----------|
| Gitleaks | JSON | `security-reports/gitleaks.json` |
| SonarQube | Dashboard | SonarQube Server |
| Snyk | JSON | `security-reports/snyk.json` |
| Trivy | JSON | `security-reports/trivy.json` |
| SBOM (SPDX) | JSON | `sbom/sbom-spdx.json` |
| SBOM (CycloneDX) | JSON | `sbom/sbom-cyclonedx.json` |

---

## Jenkins Credentials Required

| ID | Type | Purpose |
|----|------|---------|
| `aws-credentials` | Username/Password | AWS Access Key ID / Secret |
| `sonarqube-url` | Secret Text | SonarQube server URL |
| `sonarqube-token` | Secret Text | SonarQube authentication |
| `snyk-token` | Secret Text | Snyk API token |

---

## Lab Deliverables Checklist

| Deliverable | Status | File |
|-------------|--------|------|
| Jenkinsfile with security scanning | ✅ | `Jenkinsfile` |
| ECS task definition template | ✅ | Generated in pipeline |
| Security reports | ✅ | `security-reports/` |
| SBOM files | ✅ | `sbom/` |
| Infrastructure as Code | ✅ | `terraform/` |
| Documentation | ✅ | `IMPLEMENTATION.md` |

---

## How to Test Security Gates

**Inject vulnerability:**
```json
// Add to package.json
"lodash": "4.17.15"  // Has CVE-2020-8203, CVE-2021-23337
```

**Expected:** Pipeline fails at Security Gate

**Fix:**
```json
"lodash": "4.17.21"  // Patched version
```

---

## How to Deploy

```bash
# 1. Deploy infrastructure
cd terraform/environments/dev
terraform init && terraform apply

# 2. Configure Jenkins with credentials

# 3. Run pipeline with parameters:
#    - AWS_ACCOUNT_ID: your-account-id
#    - AWS_REGION: us-east-1
#    - ECS_CLUSTER: from terraform output
#    - ECS_SERVICE: from terraform output
```
