output src_url {
  value = aws_codecommit_repository.lambda_src.clone_url_ssh
}

output project_arn {
  value = aws_codebuild_project.lambda.arn
}

output badge_url {
  value = aws_codebuild_project.lambda.badge_url
}
