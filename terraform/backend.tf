## Backend configuration for Terraform state
## Uses existing S3 bucket 'chxtwo-git' (created by user)
## If you want state locking, create the DynamoDB table and uncomment the dynamodb_table line below.

terraform {
  backend "s3" {
    bucket = "chxtwo-git"
    # key is the path inside the bucket where the state will be stored
    key    = "git-ac/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true

    # Uncomment the following line after you create the DynamoDB table for locking.
    # dynamodb_table = "terraform-state-lock"
  }
}

# Notes:
# - The S3 bucket must already exist before running `terraform init` with this backend.
# - If you need locking (recommended for team/CI), create a DynamoDB table named
#   `terraform-state-lock` (or change the name above) with a primary key `LockID` (String).
# - To enable locking now, create the DynamoDB table (see README or run the AWS CLI command
#   shown in the guidance), then uncomment the dynamodb_table line and run:
#     terraform init -reconfigure
