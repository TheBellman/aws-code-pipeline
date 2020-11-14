# ------------------------------------------------------------------------------------------------
# build logs
# ------------------------------------------------------------------------------------------------
resource aws_cloudwatch_log_group lambda {
  name              = "/aws/codebuild/${local.name}"
  retention_in_days = 90

  tags = merge({ "Name" = "${local.name}-codebuild" }, var.tags)
}
