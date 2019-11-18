terraform {
 required_version = ">= 0.12"
 backend "s3" {
 encrypt = true
 #bucket = "${var.env}-terraform-backend-store" this doesn't work
 bucket = "dev-terraform-backend-store"
 region = "us-west-2"
 workspace_key_prefix = "environment"
 key = "tfstate"
 }
}
