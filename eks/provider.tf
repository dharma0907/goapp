//we are creating provider in aws along with region
/*terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">= 2.0.0"
    }
  }
}*/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
