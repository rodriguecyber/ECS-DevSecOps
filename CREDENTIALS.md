# 🔐 Credentials Guide

This document provides detailed instructions for obtaining and configuring all required credentials for the Secure CI/CD Pipeline.

---

## 📋 Overview

| # | Credential | Purpose | Where to Store |
|---|------------|---------|----------------|
| 1 | AWS Access Key ID | Infrastructure & Deployment | Jenkins + Local |
| 2 | AWS Secret Access Key | Infrastructure & Deployment | Jenkins + Local |
| 3 | SonarQube URL | SAST Code Analysis | Jenkins |
| 4 | SonarQube Token | SAST Authentication | Jenkins |
| 5 | Snyk Token | SCA Vulnerability Scanning | Jenkins |

---

## 1️⃣ AWS Credentials

### Purpose
- Deploy infrastructure with Terraform
- Push Docker images to ECR
- Deploy containers to ECS
- Create/manage AWS resources

### How to Obtain

1. **Login to AWS Console**
   - Go to: https://console.aws.amazon.com/iam/

2. **Create IAM User**
   ```
   IAM → Users → Add User
   - Username: jenkins-cicd
   - Access type: Programmatic access
   ```

3. **Attach Policies**
   - `AmazonECS_FullAccess`
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonVPCFullAccess`
   - `IAMFullAccess`
   - `AmazonS3FullAccess`
   - `AmazonDynamoDBFullAccess`
   - `CloudWatchLogsFullAccess`
   - `ElasticLoadBalancingFullAccess`

4. **Save Credentials**
   - Access Key ID: `AKIAXXXXXXXXXXXXXXXXXX`
   - Secret Access Key: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   
   ⚠️ **Save these immediately - Secret Key shown only once!**

### Where to Configure

#### Local Machine (for Terraform/Scripts)

```bash
aws configure
```

Enter when prompted:
```
AWS Access Key ID [None]: AKIAXXXXXXXXXXXXXXXXXX
AWS Secret Access Key [None]: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Default region name [None]: eu-north-1
Default output format [None]: json
```

Verify:
```bash
aws sts get-caller-identity
```

#### Jenkins (for Pipeline)

1. Navigate to: `Manage Jenkins` → `Credentials` → `System` → `Global credentials`
2. Click: `Add Credentials`
3. Fill in:

| Field | Value |
|-------|-------|
| Kind | Username with password |
| Scope | Global |
| Username | `AKIAXXXXXXXXXXXXXXXXXX` (Access Key ID) |
| Password | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (Secret Access Key) |
| ID | `aws-credentials` |
| Description | AWS credentials for CI/CD pipeline |

---

## 2️⃣ SonarQube Credentials

### Purpose
- Static Application Security Testing (SAST)
- Code quality analysis
- Bug and vulnerability detection

### Option A: SonarCloud (Recommended - Free)

1. **Create Account**
   - Go to: https://sonarcloud.io
   - Click: `Log in` → `Log in with GitHub`

2. **Create Organization**
   - Click: `+` → `Create new organization`
   - Follow the prompts

3. **Generate Token**
   - Click: Your avatar (top right) → `My Account`
   - Go to: `Security` tab
   - Token name: `jenkins-pipeline-token`
   - Click: `Generate`
   - **Copy the token** (shown only once!)

4. **Token Format**
   ```
   sqp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

5. **SonarQube URL**
   ```
   https://sonarcloud.io
   ```

### Option B: Self-Hosted SonarQube

1. **Start SonarQube with Docker**
   ```bash
   docker run -d --name sonarqube \
     -p 9000:9000 \
     -v sonarqube_data:/opt/sonarqube/data \
     -v sonarqube_logs:/opt/sonarqube/logs \
     sonarqube:lts-community
   ```

2. **Wait for Startup** (~2 minutes)
   ```bash
   # Check if ready
   curl -s http://localhost:9000/api/system/status | jq .status
   # Should return "UP"
   ```

3. **Initial Login**
   - URL: http://localhost:9000
   - Username: `admin`
   - Password: `admin`
   - Change password on first login

4. **Generate Token**
   - Go to: `Administration` → `Security` → `Users`
   - Click: Your user → `Tokens`
   - Name: `jenkins-token`
   - Click: `Generate`
   - **Copy the token**

5. **Token Format**
   ```
   squ_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

### Where to Configure in Jenkins

#### SonarQube URL

1. Navigate to: `Manage Jenkins` → `Credentials` → `System` → `Global credentials`
2. Click: `Add Credentials`
3. Fill in:

| Field | Value |
|-------|-------|
| Kind | Secret text |
| Scope | Global |
| Secret | `https://sonarcloud.io` (or `http://your-server:9000`) |
| ID | `sonarqube-url` |
| Description | SonarQube Server URL |

#### SonarQube Token

1. Navigate to: `Manage Jenkins` → `Credentials` → `System` → `Global credentials`
2. Click: `Add Credentials`
3. Fill in:

| Field | Value |
|-------|-------|
| Kind | Secret text |
| Scope | Global |
| Secret | `sqp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| ID | `sonarqube-token` |
| Description | SonarQube Authentication Token |

#### Configure SonarQube Server

1. Navigate to: `Manage Jenkins` → `Configure System`
2. Scroll to: `SonarQube servers`
3. Check: ✅ `Environment variables`
4. Click: `Add SonarQube`
5. Fill in:

| Field | Value |
|-------|-------|
| Name | `SonarQube` |
| Server URL | `https://sonarcloud.io` |
| Server authentication token | Select `sonarqube-token` from dropdown |

---

## 3️⃣ Snyk Credentials

### Purpose
- Software Composition Analysis (SCA)
- Dependency vulnerability scanning
- License compliance checking

### How to Obtain

1. **Create Account**
   - Go to: https://snyk.io
   - Click: `Sign up free`
   - Choose: `Sign up with GitHub`

2. **Get API Token**
   - Click: Your name (bottom left) → `Account Settings`
   - Scroll to: `API Token` section
   - Click: `click to show` (or `Regenerate`)
   - **Copy the token**

3. **Token Format**
   ```
   xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

### Where to Configure in Jenkins

1. Navigate to: `Manage Jenkins` → `Credentials` → `System` → `Global credentials`
2. Click: `Add Credentials`
3. Fill in:

| Field | Value |
|-------|-------|
| Kind | Secret text |
| Scope | Global |
| Secret | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| ID | `snyk-token` |
| Description | Snyk API Token for vulnerability scanning |

---

## ✅ Verification Checklist

After configuring all credentials, verify in Jenkins:

1. Go to: `Manage Jenkins` → `Credentials` → `System` → `Global credentials`

2. You should see these 4 credentials:

| ID | Kind | Status |
|----|------|--------|
| `aws-credentials` | Username with password | ✅ |
| `sonarqube-url` | Secret text | ✅ |
| `sonarqube-token` | Secret text | ✅ |
| `snyk-token` | Secret text | ✅ |

3. Verify SonarQube server configuration:
   - Go to: `Manage Jenkins` → `Configure System`
   - Scroll to: `SonarQube servers`
   - Verify `SonarQube` entry exists with correct URL

---

## 🔒 Security Best Practices

### DO ✅

- Store credentials only in Jenkins credentials store
- Use IAM user with minimum required permissions
- Rotate credentials periodically
- Use different credentials for dev/prod environments
- Enable MFA on AWS account

### DON'T ❌

- Commit credentials to Git
- Share credentials via email/chat
- Use root AWS account credentials
- Hardcode credentials in Jenkinsfile
- Store credentials in plain text files

---

## 🔄 Credential Rotation

### AWS Credentials

1. Create new access key in IAM
2. Update Jenkins credential
3. Update local `aws configure`
4. Verify pipeline works
5. Deactivate old key
6. Delete old key after 24 hours

### SonarQube Token

1. Generate new token in SonarQube
2. Update `sonarqube-token` in Jenkins
3. Verify pipeline works
4. Revoke old token

### Snyk Token

1. Regenerate token in Snyk account
2. Update `snyk-token` in Jenkins
3. Verify pipeline works

---

## 📞 Troubleshooting

### "AWS credentials not valid"

```bash
# Verify locally
aws sts get-caller-identity

# Check expiration (if using temporary credentials)
aws sts get-caller-identity --query 'Arn'
```

### "SonarQube authentication failed"

1. Verify token is not expired
2. Check URL includes correct protocol (http/https)
3. Verify organization exists (SonarCloud)
4. Check network connectivity

### "Snyk authentication failed"

```bash
# Verify token locally
SNYK_TOKEN=your-token snyk auth

# Check token validity
snyk whoami
```

---

## 📁 Related Files

- `Jenkinsfile` - Pipeline definition using these credentials
- `sonar-project.properties` - SonarQube project configuration
- `.snyk` - Snyk policy file
- `scripts/setup-backend.sh` - Uses AWS credentials
