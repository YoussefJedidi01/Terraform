resource "aws_s3_bucket" "mybucket" {
  bucket = "s3statebucket2024s"
}
 
resource "aws_s3_bucket_versioning" "versioning_example_S3_bucket" {
bucket = aws_s3_bucket.mybucket.id
 
  versioning_configuration {
    status = "Enabled"
  }
}
 
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_example_S3_bucket" {
bucket = aws_s3_bucket.mybucket.id
 
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
 
# Create DynamoDB table
resource "aws_dynamodb_table" "statelock" {
  name         = "state-lock-jedidi"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
 
  attribute {
    name = "LockID"
    type = "S"
  }
}
