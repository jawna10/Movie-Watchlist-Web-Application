# Security Group for EKS Nodes
resource "aws_security_group" "node" {
  name_prefix = "${var.project_name}-${var.environment}-node-"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-node-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Allow all outbound traffic from nodes
resource "aws_security_group_rule" "node_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node.id
  description       = "Allow all outbound traffic"
}

# Allow nodes to communicate with each other
resource "aws_security_group_rule" "node_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.node.id
  description       = "Allow nodes to communicate with each other"
}

# Allow pods to communicate with the EKS cluster API
resource "aws_security_group_rule" "node_ingress_cluster" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.node.id
  description       = "Allow pods to communicate with cluster API"
}