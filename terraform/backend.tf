terraform {
  backend "s3" {
    bucket = "nikhil-devops-terraform-state-bucket"
    key    = "ecs-fargate/terraform.tfstate"
    region = "ap-south-2"
    encrypt = true
  }
}
