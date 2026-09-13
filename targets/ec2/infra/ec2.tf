resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.instance.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = <<-USERDATA
    #!/bin/bash
    set -euo pipefail
    mkdir -p /opt/shipstack-ec2/releases
    dnf install -y java-21-amazon-corretto-headless
    java -version
    command -v curl
    touch /opt/shipstack-ec2/instance-bootstrap-complete
  USERDATA

  tags = { Name = local.ec2_instance_name }
}
