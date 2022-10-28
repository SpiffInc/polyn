terraform {
  // Configure a [backend](https://www.terraform.io/language/settings/backends/configuration)
  // to store your `terraform.tfstate` file in for production use
  backend "remote" {
  }
}
