# ------------------------------------------------------------------------------------------------
# the pipeline
# ------------------------------------------------------------------------------------------------
resource aws_codepipeline lambda {
  name     = local.name
  role_arn = aws_iam_role.pipeline.arn
  tags     = merge({ "Name" = local.name }, var.tags)

  artifact_store {
    location = var.bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      category = "Source"
      owner    = "AWS"
      name     = "Source"
      provider = "CodeCommit"
      version  = "1"
      configuration = {
        "BranchName"           = "master"
        "OutputArtifactFormat" = "CODEBUILD_CLONE_REF"
        "PollForSourceChanges" = "false"
        "RepositoryName"       = local.name
      }
      input_artifacts  = []
      output_artifacts = ["SourceArtifact"]
      namespace        = "SourceVariables"
      region           = var.aws_region
      run_order        = 1
    }
  }

  stage {
    name = "Build"

    action {
      category = "Build"
      owner    = "AWS"
      name     = "Build"
      provider = "CodeBuild"
      version  = "1"
      configuration = {
        "ProjectName" = local.name
      }
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      namespace        = "BuildVariables"
      region           = var.aws_region
      run_order        = 1
    }
  }

  stage {
    name = "Deploy"

    action {
      category = "Deploy"
      owner    = "AWS"
      name     = "Deploy_to_S3"
      provider = "S3"
      version  = "1"
      configuration = {
        "BucketName" = var.bucket_name
        "Extract"    = "false"
        "ObjectKey"  = "${local.name}/${local.name}.{datetime}.zip"
      }
      input_artifacts  = ["BuildArtifact", ]
      output_artifacts = []
      region           = var.aws_region
      run_order        = 1
    }
  }
}
