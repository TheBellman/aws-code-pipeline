# ------------------------------------------------------------------------------------------------
# build project
# ------------------------------------------------------------------------------------------------
resource aws_codebuild_project lambda {
  name         = local.name
  description  = "example project to construct a lambda function in Go"
  service_role = aws_iam_role.codebuild.arn

  build_timeout  = 15
  badge_enabled  = true
  source_version = "refs/heads/master"

  source {
    git_clone_depth     = 1
    insecure_ssl        = false
    location            = aws_codecommit_repository.lambda_src.clone_url_http
    report_build_status = false
    type                = "CODECOMMIT"

    git_submodules_config {
      fetch_submodules = false
    }
  }

  artifacts {
    encryption_disabled    = false
    location               = var.bucket_name
    name                   = local.name
    namespace_type         = "NONE"
    override_artifact_name = true
    packaging              = "ZIP"
    path                   = local.name
    type                   = "S3"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = aws_cloudwatch_log_group.lambda.name
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  tags = merge({ "Name" = local.name }, var.tags)
}
