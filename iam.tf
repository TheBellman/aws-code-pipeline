# ------------------------------------------------------------------------------------------------
# permissions for code pipeline
# ------------------------------------------------------------------------------------------------
data aws_iam_policy_document pipeline_assume {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource aws_iam_role pipeline {
  name               = "${local.name}-pipeline"
  description        = "role allowing pipeline access to relevant resources"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume.json

  force_detach_policies = true
  tags                  = merge({ "Name" = "${local.name}-pipeline" }, var.tags)
}

// this is much broader than needed but is derived from the standard policy built by AWS
data aws_iam_policy_document pipeline {
  statement {
    actions   = ["iam:PassRole"]
    resources = ["*"]

    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"
      values = [
        "cloudformation.amazonaws.com",
        "elasticbeanstalk.amazonaws.com",
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
  statement {
    actions = [
      "codecommit:CancelUploadArchive",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetRepository",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:UploadArchive"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["codestar-connections:UseConnection"]
    resources = ["*"]
  }
  statement {
    actions = [
      "elasticbeanstalk:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "cloudformation:*",
      "rds:*",
      "sqs:*",
      "ecs:*"
    ]
    resources = ["*"]
  }
  statement {
    actions   = ["lambda:InvokeFunction", "lambda:ListFunctions"]
    resources = ["*"]
  }
  statement {
    actions = ["opsworks:CreateDeployment",
      "opsworks:DescribeApps",
      "opsworks:DescribeCommands",
      "opsworks:DescribeDeployments",
      "opsworks:DescribeInstances",
      "opsworks:DescribeStacks",
      "opsworks:UpdateApp",
      "opsworks:UpdateStack"
    ]
    resources = ["*"]
  }
  statement {
    actions = ["cloudformation:CreateStack",
      "cloudformation:DeleteStack",
      "cloudformation:DescribeStacks",
      "cloudformation:UpdateStack",
      "cloudformation:CreateChangeSet",
      "cloudformation:DeleteChangeSet",
      "cloudformation:DescribeChangeSet",
      "cloudformation:ExecuteChangeSet",
      "cloudformation:SetStackPolicy",
      "cloudformation:ValidateTemplate"
    ]
    resources = ["*"]
  }
  statement {
    actions = ["codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuildBatches",
      "codebuild:StartBuildBatch"
    ]
    resources = ["*"]
  }
  statement {
    actions = ["devicefarm:ListProjects",
      "devicefarm:ListDevicePools",
      "devicefarm:GetRun",
      "devicefarm:GetUpload",
      "devicefarm:CreateUpload",
      "devicefarm:ScheduleRun"
    ]
    resources = ["*"]
  }
  statement {
    actions = ["servicecatalog:ListProvisioningArtifacts",
      "servicecatalog:CreateProvisioningArtifact",
      "servicecatalog:DescribeProvisioningArtifact",
      "servicecatalog:DeleteProvisioningArtifact",
      "servicecatalog:UpdateProduct"
    ]
    resources = ["*"]
  }
  statement {
    actions = ["cloudformation:ValidateTemplate"
    ]
    resources = ["*"]
  }
  statement {
    actions = ["ecr:DescribeImages"
    ]
    resources = ["*"]
  }
  statement {
    actions = ["states:DescribeExecution",
      "states:DescribeStateMachine",
      "states:StartExecution"
    ]
    resources = ["*"]
  }
  statement {
    actions = ["appconfig:StartDeployment",
      "appconfig:StopDeployment",
      "appconfig:GetDeployment"
    ]
    resources = ["*"]
  }
}

resource aws_iam_role_policy pipeline {
  name   = "${local.name}-pipeline"
  role   = aws_iam_role.pipeline.name
  policy = data.aws_iam_policy_document.pipeline.json
}

# ------------------------------------------------------------------------------------------------
# permissions for the build
# ------------------------------------------------------------------------------------------------
data aws_iam_policy_document codebuild_assume {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

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
    sid       = "read"
    resources = ["arn:aws:s3:::${var.bucket_name}/${local.name}", "arn:aws:s3:::${var.bucket_name}/${local.name}/*"]
    actions   = ["s3:GetObject", "s3:GetObjectAcl"]
  }

  #
  # statement {
  #   sid       = "reportgroup"
  #   resources = ["arn:aws:codebuild:${var.aws_region}:${var.aws_account_id}:report-group/${local.name}-*"]
  #   actions = [
  #     "codebuild:CreateReportGroup",
  #     "codebuild:CreateReport",
  #     "codebuild:UpdateReport",
  #     "codebuild:BatchPutTestCases",
  #     "codebuild:BatchPutCodeCoverages"
  #   ]
  # }
}

resource aws_iam_role_policy codebuild {
  name   = "${local.name}-codebuild"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild.json
}

# ------------------------------------------------------------------------------------------------
# permissions for commit event to trigger pipeline
# ------------------------------------------------------------------------------------------------
data aws_iam_policy_document event_assume {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource aws_iam_role event {
  name                  = "${local.name}-pipeline-trigger"
  description           = "this allows EventBridge to trigger the pipeline when it notices a commit"
  assume_role_policy    = data.aws_iam_policy_document.event_assume.json
  force_detach_policies = true
  tags                  = merge({ "Name" = "${local.name}-pipeline-trigger" }, var.tags)
}

data aws_iam_policy_document event {
  statement {
    sid       = "start"
    resources = [aws_codepipeline.lambda.arn]
    actions   = ["codepipeline:StartPipelineExecution"]
  }
}

resource aws_iam_role_policy event {
  name   = "${local.name}-pipeline-trigger"
  role   = aws_iam_role.event.name
  policy = data.aws_iam_policy_document.event.json
}
