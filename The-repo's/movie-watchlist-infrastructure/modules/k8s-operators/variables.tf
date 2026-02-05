variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "ebs_csi_role_arn" {
  description = "IAM role ARN for EBS CSI driver"
  type        = string
}

variable "admin_email" {
  description = "Email for Let's Encrypt certificates"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}