# ------------------------------------------------------------------------------------------------
# Git repositories
# ------------------------------------------------------------------------------------------------
resource aws_codecommit_repository lambda_src {
  repository_name = local.name
  description     = "Source for lambda example"
  tags            = merge({ "Name" = local.name }, var.tags)
}
