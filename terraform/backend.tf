terraform {
  required_version = "~>1.12.0"

  backend "s3" {

    profile = "default"
    region  = "ru-central1"

    bucket  = "klimenko-tfstate-develop" 
    key     = "final-terraform.tfstate"
    encrypt = false

    use_lockfile = true

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
  }
}