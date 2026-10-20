terraform {
  backend "s3" {
    bucket         = "demo-project-mani-s3"
    key            = "qc/terraform.tfstate"   
    region         = "ap-southeast-2"
    encrypt        = true
  }
}