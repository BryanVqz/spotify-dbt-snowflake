terraform {
  backend "s3" {
    bucket         = "spotify-terraform-state-bryan"
    key            = "spotify-pipeline/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-spotify"
    encrypt        = true
  }
}
