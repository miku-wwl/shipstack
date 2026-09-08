resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = false }
  force_delete = true
  tags         = { Name = "${var.name_prefix}-ecr" }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [{ rulePriority = 1, description = "Keep the latest 20 release images", selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 20 }, action = { type = "expire" } }]
  })
}
