You should define the following Terraform modules:
- fluent-bit-daemonset.tf (for EKS log shipping)
- grafana-eks.tf (Grafana Helm chart deployment on EKS)
- prometheus-eks.tf (Prometheus Helm chart deployment on EKS)
- cloudwatch-alarms.tf (reusable alarm templates for Kinesis, EMR, EKS)
- log-groups.tf (CloudWatch Log Groups for Kinesis, EMR, EKS)