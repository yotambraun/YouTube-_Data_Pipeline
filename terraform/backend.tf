terraform {
  backend "s3" {
    bucket = "youtube-pipeline-terraform-state"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}