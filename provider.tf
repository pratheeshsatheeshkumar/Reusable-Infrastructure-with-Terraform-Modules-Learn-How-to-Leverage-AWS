/*==== Provider ======*/
/* Setting up of provider name and associated authentication */

provider "aws" {

  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key

  default_tags {
    tags = local.common_tags
  }
}


/*==== S3 Remote Backend Configuration ======*/
/* Setting up of S3 bucket as remote backend.  */

terraform {
  backend "s3" {

    access_key = "AKIAYHVF6JBOY34ZLHWR"
    secret_key = "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"
    bucket = "terraform-pratheesh.tech"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}