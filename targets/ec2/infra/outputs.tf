output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.id
}

output "aws_region" {
  value = var.aws_region
}

output "source_object_key" {
  value = var.source_object_key
}

output "ec2_instance_id" {
  value = aws_instance.this.id
}

output "ec2_public_ip" {
  value = aws_instance.this.public_ip
}

output "ec2_private_ip" {
  value = aws_instance.this.private_ip
}

output "ec2_app_endpoint" {
  value = "http://${aws_instance.this.public_ip}:${var.app_port}"
}

output "codebuild_project_name" {
  value = aws_codebuild_project.this.name
}

output "codepipeline_name" {
  value = aws_codepipeline.this.name
}

output "codebuild_log_group_name" {
  value = aws_cloudwatch_log_group.codebuild.name
}
