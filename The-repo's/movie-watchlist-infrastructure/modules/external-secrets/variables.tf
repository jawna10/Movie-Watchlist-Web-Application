variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets"
  type        = string
}