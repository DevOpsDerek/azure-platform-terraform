terraform {
  required_version = "= 1.9.8"
}

module "governance" {
  source          = "../.."
  subscription_id = "00000000-0000-0000-0000-000000000000"

  required_tags = ["owner"]
}
