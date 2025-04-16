## Folder structure

terraform/
├── modules/                # All reusable modules
│   ├── s3-bucket/
│   ├── vpc/
│   ├── eks/
│   └── kinesis/
├── backend/                # DynamoDB + S3 for state lock
├── stacks/                 # Each layer’s composition
│   ├── core/               # VPC, IAM, DNS
│   ├── platform/           # EKS, K8s core apps
│   ├── app/                # Business services
│   └── observability/      # CloudWatch, Prometheus
├── environments/           # Inputs per env
│   ├── dev/
│   ├── qa/
│   └── prod/
