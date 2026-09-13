data "aws_iam_policy_document" "eks_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "nodes_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${local.name_prefix}-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_nodes" {
  name               = "${local.name_prefix}-nodes"
  assume_role_policy = data.aws_iam_policy_document.nodes_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ])

  role       = aws_iam_role.eks_nodes.name
  policy_arn = each.value
}

resource "aws_iam_role" "codebuild" {
  name               = "${local.name_prefix}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role" "codepipeline" {
  name               = "${local.name_prefix}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["logs:CreateLogGroup"], Resource = "*" },
      { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${aws_cloudwatch_log_group.codebuild.arn}:*" },
      { Effect = "Allow", Action = ["s3:GetBucketLocation", "s3:GetBucketVersioning", "s3:ListBucket"], Resource = aws_s3_bucket.artifacts.arn },
      { Effect = "Allow", Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"], Resource = "${aws_s3_bucket.artifacts.arn}/*" },
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      { Effect = "Allow", Action = ["ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload", "ecr:InitiateLayerUpload", "ecr:PutImage", "ecr:UploadLayerPart"], Resource = aws_ecr_repository.this.arn },
      { Effect = "Allow", Action = ["eks:DescribeCluster"], Resource = aws_eks_cluster.this.arn },
      { Effect = "Allow", Action = ["sts:GetCallerIdentity"], Resource = "*" }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  role = aws_iam_role.codepipeline.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:GetBucketAcl", "s3:GetBucketLocation", "s3:GetBucketVersioning", "s3:ListBucket"], Resource = aws_s3_bucket.artifacts.arn },
      { Effect = "Allow", Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"], Resource = "${aws_s3_bucket.artifacts.arn}/*" },
      { Effect = "Allow", Action = ["codebuild:StartBuild", "codebuild:BatchGetProjects", "codebuild:BatchGetBuilds"], Resource = "*" }
    ]
  })
}
