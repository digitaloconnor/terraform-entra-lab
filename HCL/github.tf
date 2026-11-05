provider "github" {
  token = var.github_token
}

resource "github_repository" "production-repo" {
  name        = "prod-repo"
  description = "An production repository created with Terraform"
  private     = true
}

