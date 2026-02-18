# GenAI Claim Status API (Lab)

This repository contains the deliverables for the GenAI-enabled Claim Status API lab.

## Folders
- src/ — service source + Dockerfile
- mocks/ — sample claim data and claim notes
- apigw/ — API Gateway artifacts
- iac/ — infrastructure-as-code templates
- pipelines/ — CI/CD pipeline definitions
- scans/ — security scan evidence
- observability/ — logs/metrics queries and screenshots

## Next steps

- Add scan and observability evidence under scans/ and observability/

## Architecture

```mermaid
flowchart LR
  subgraph Internet
    Client[Client]
  end

  subgraph CI_CD[CI/CD]
    GitHub[GitHub Repository]
    CP[AWS CodePipeline]
    CB[AWS CodeBuild]
  end

  Client --> APIGW[Amazon API Gateway HTTP API]

  subgraph VPC
    subgraph PublicSubnets[Public Subnets]
      NLB[Network Load Balancer]
    end
    subgraph PrivateSubnets[Private Subnets]
      EKS[Amazon EKS Auto Mode]
      Nodes[EC2 Worker Nodes]
      Svc[Kubernetes Service]
      Deploy[Claim Status Deployment]
      Pods[Claim Status API Pods]
    end
  end

  APIGW --> NLB --> Svc --> Pods
  EKS --> Nodes
  Deploy --> Pods
  Nodes --> Pods

  Pods --> DDB[Amazon DynamoDB claims table]
  Pods --> S3[Amazon S3 claim notes]
  Pods --> Bedrock[Amazon Bedrock]
  Pods --> CW[Amazon CloudWatch]

  GitHub --> CP --> CB --> ECR[Amazon ECR]
  CB --> Deploy
  ECR --> Inspector[Amazon Inspector]
  Inspector --> SecurityHub[AWS Security Hub]
```
## Architectural Reasoning

- EKS on EC2 was chosen to match the lab constraint (no Fargate) and to keep Kubernetes control over node sizing, networking, and add‑ons. Compared to ECS or Lambda, EKS provides closer parity with enterprise platform expectations and existing K8s operational practices.

- API Gateway (HTTP API) fronts the cluster to provide managed ingress, throttling, and auth integration without exposing the NLB directly. Compared to ALB-only ingress, this adds a stable public entry point and standardized API controls.

- DynamoDB stores claim status because it offers low‑latency reads, simple key‑value access for `GET /claims/{id}`, and no schema management. Compared to RDS, it avoids database administration and scales with demand.

- S3 stores claim notes to separate large unstructured content from transactional status data. Compared to storing notes in DynamoDB, S3 is cheaper for larger objects and integrates directly with batch/analytics tooling.

- Amazon Bedrock is used for summarization to satisfy GenAI requirements while keeping model selection and access governed by AWS. Compared to external model APIs, Bedrock simplifies network egress controls and IAM policy management.

- CodePipeline + CodeBuild provide AWS‑native CI/CD with ECR publishing and kubectl deployment to EKS. Compared to self‑hosted CI, this reduces operational overhead and integrates with IAM and audit trails.

- Amazon Inspector + Security Hub provide automated image scanning and centralized findings. Compared to ad‑hoc scanning scripts, this standardizes vulnerability management and reporting.

## Service Deployment

```mermaid
flowchart TB
  Dev[Developer] --> GitHub[GitHub Repository]
  GitHub --> CP[AWS CodePipeline]
  CP --> CB[AWS CodeBuild]
  CB --> ECR[Amazon ECR]
  CB --> EKSDeploy[Kubectl Deploy]
  EKSDeploy --> EKS[Amazon EKS Auto Mode]
  EKS --> Pods[Claim Status API Pods]
  Pods --> APIGW[Amazon API Gateway HTTP API]
  APIGW --> Client[Client]
```

## Infrastructure Deployment

Run these commands from the iac/ directory.

### Verify AWS login

```
aws sts get-caller-identity --profile cna-lab-1
```

### State cleanup (only if infra was deleted outside Terraform)

```
terraform state list
terraform state list | xargs -n1 terraform state rm
```

Alternative (fast): delete the local state files in iac/ (terraform.tfstate, terraform.tfstate.backup) and the .terraform folder.

Git Bash:
```
rm -f terraform.tfstate terraform.tfstate.backup
rm -rf .terraform
```

### Fresh init + apply

```
terraform init -upgrade
terraform plan
terraform apply
```

### Apply changes when already initialized

```
terraform plan
terraform apply
```

## CodePipeline Source Connection Fix (First Run)

If the pipeline fails with “Connection claim-status-github is not available”, authorize the CodeStar connection in the AWS Console:

1. Open AWS Console → Developer Tools → Settings → Connections.
2. Select claim-status-github.
3. Click Update pending connection and complete the GitHub authorization.
4. Re-run the pipeline.




