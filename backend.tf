terraform {
  # backend "s3" {}
  backend "local" {
    path = "tf_state/monitoring.tfstate"
  }
}