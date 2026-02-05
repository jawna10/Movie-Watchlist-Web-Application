terraform {
  backend "s3" {
    bucket         = "terraform-state-jawna"  
    key            = "movie-watchlist/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"  
  }
}