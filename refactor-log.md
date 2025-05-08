
## Helm
- [] inject image and repo name to `values.yaml`
- [] Add ingress.yaml + TLS, WAF/Shield integration (security)
- [] Add readiness/liveness probes, autoscaling, HPA (availability)
- [] Include sidecars (Fluent Bit, Prometheus exporters) (observability)

## CI/CD
- [] use `role-to-assume` in GitHub Actions to avoid AWS credentials in GitHub
- [] Use CI/CD pipeline to publish updated Helm charts
- [] Bring in ArgoCD for EKS deployments


## Security
- [] ass image scanning (e.g., Trivy)
- [] roate ECR credentials