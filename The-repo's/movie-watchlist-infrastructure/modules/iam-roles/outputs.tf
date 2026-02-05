output "ebs_csi_role_arn" {
  description = "EBS CSI Driver IAM role ARN"
  value       = aws_iam_role.ebs_csi.arn
}

output "alb_controller_role_arn" {
  description = "ALB Controller IAM role ARN"
  value       = aws_iam_role.alb_controller.arn
}

output "external_secrets_role_arn" {
  description = "External Secrets IAM role ARN"
  value       = aws_iam_role.external_secrets.arn
}