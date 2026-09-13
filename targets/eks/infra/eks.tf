resource "aws_eks_cluster" "this" {
  name     = local.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]

  tags = {
    Name   = local.eks_cluster_name
    Target = "eks"
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = local.eks_node_group_name
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = 1
    max_size     = 2
  }

  depends_on = [aws_iam_role_policy_attachment.eks_nodes]

  tags = {
    Name   = local.eks_node_group_name
    Target = "eks"
  }
}
