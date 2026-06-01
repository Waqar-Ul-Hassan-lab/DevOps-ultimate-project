provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "eks-state-bucket" {
  bucket = "terraform-eks-state-waqarhasan-bucket"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {

  name         = "Terraform-State-Lock-Table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
