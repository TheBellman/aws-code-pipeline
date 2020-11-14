locals {
  name = "go-lambda-example"
}

data aws_iam_policy_document codebuild_assume {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

# ------------------------------------------------------------------------------------------------
# Git repositories
# ------------------------------------------------------------------------------------------------
resource aws_codecommit_repository lambda_src {
  repository_name = local.name
  description     = "Source for lambda example"
  tags            = merge({ "Name" = local.name }, var.tags)
}

# ------------------------------------------------------------------------------------------------
# permissions for the build
# ------------------------------------------------------------------------------------------------
resource aws_iam_role codebuild {
  name               = "${local.name}-codebuild"
  description        = "role allowing codebuild access to relevant resources"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json

  force_detach_policies = true
  tags                  = merge({ "Name" = "${local.name}-codebuild" }, var.tags)
}

data aws_iam_policy_document codebuild {
  statement {
    sid     = "createlogs"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/codebuild/${local.name}",
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/codebuild/${local.name}:*"
    ]
  }

  statement {
    sid       = "s3"
    resources = ["arn:aws:s3:::codepipeline-${var.aws_region}-*"]
    actions   = ["s3:PutObject", "s3:GetObject", "s3:GetObjectVersion", "s3:GetBucketAcl", "s3:GetBucketLocation"]
  }

  statement {
    sid       = "gitpull"
    resources = ["arn:aws:codecommit:eu-west-2:889199313043:${local.name}"]
    actions   = ["codecommit:GitPull"]
  }

  statement {
    sid       = "push"
    resources = ["arn:aws:s3:::${var.bucket_name}", "arn:aws:s3:::${var.bucket_name}/*"]
    actions   = ["s3:PutObject", "s3:GetBucketAcl", "s3:GetBucketLocation"]
  }

  statement {
    sid       = "reportgroup"
    resources = ["arn:aws:codebuild:${var.aws_region}:${var.aws_account_id}:report-group/${local.name}-*"]
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ]
  }
}

resource aws_iam_role_policy codebuild {
  name   = "${local.name}-codebuild"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild.json
}

# ------------------------------------------------------------------------------------------------
# build logs
# ------------------------------------------------------------------------------------------------
resource aws_cloudwatch_log_group lambda {
  name              = "/aws/codebuild/${local.name}"
  retention_in_days = 90

  tags = merge({ "Name" = "${local.name}-codebuild" }, var.tags)
}

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
      status      = "ENABLED"
      group_name  = aws_cloudwatch_log_group.lambda.name
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  tags = merge({ "Name" = local.name }, var.tags)
}
