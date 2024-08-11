terraform {
  
  backend "s3" {
    bucket         = "s3statebucket2024s"
    key            = "global/mystatefile/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "state-lock-jedidi"
  }

    
}


provider "aws" {
  region = "us-east-1"
}

