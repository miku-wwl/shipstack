resource "aws_elastic_beanstalk_application" "this" {
  name        = local.eb_application_name
  description = "Shipstack Elastic Beanstalk control-plane learning application"
}
