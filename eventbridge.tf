# ------------------------------------------------------------------------------------------------
# event bridge resources to allow the commit event to trigger a build
# ------------------------------------------------------------------------------------------------
resource aws_cloudwatch_event_rule lambda {
  name           = "${local.name}-build"
  description    = "Rule to start pipeline on commit into CodeCommit"
  is_enabled     = true

  event_pattern = jsonencode(
    {
      detail = {
        event         = ["referenceCreated", "referenceUpdated"]
        referenceName = ["master"]
        referenceType = ["branch"]
      }
      detail-type = ["CodeCommit Repository State Change"]
      resources   = [aws_codecommit_repository.lambda_src.arn]
      source      = ["aws.codecommit"]
    }
  )

  tags = merge({ "Name" = local.name }, var.tags)
}

resource aws_cloudwatch_event_target lambda {
  target_id      = "codepipeline-${local.name}"
  rule           = aws_cloudwatch_event_rule.lambda.name
  arn            = aws_codepipeline.lambda.arn

  # build this
  role_arn = aws_iam_role.event.arn
}
