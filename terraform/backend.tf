terraform {
  backend "s3" {
    bucket = "louieb-listy"
    key    = "tf"
    region = "us-east-1"
  }
}
