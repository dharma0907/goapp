terraform {
  backend "s3" {
    bucket = "goapp-backupfile"
    region = "us-east-1"
    key = "eks/terraform.tfstate"
  }
}
