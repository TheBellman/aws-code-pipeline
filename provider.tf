provider aws {
  version = ">= 3.6.0"
  region  = var.aws_region
  profile = var.aws_profile
}

provider aws {
  alias   = "us-east-1"
  version = ">= 3.6.0"
  region  = "us-east-1"
  profile = var.aws_profile
}
