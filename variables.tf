variable tags {
  type = map(string)

  default = {
    "Owner"   = "Robert"
    "Client"  = "Little Dog Digital"
    "Project" = "aws-code-pipeline"
  }
}

/* variables to inject via terraform.tfvars */
variable bucket_name {
  description = "name of bucket in which to store build artefacts"
  type        = string
}

variable aws_region {
  description = "region in which to build resources"
  type        = string
}

variable aws_account_id {
  description = "account in which to build resources"
  type        = string
}

variable aws_profile {
  description = "IAM ID used for building"
  type        = string
}
