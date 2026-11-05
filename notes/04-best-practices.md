# Terraform & HCL — Best Practices

**Exam Objectives Covered:** 3g, 4c, 4h, 6b, 6c

---

## 1. File Extensions

Always use `.tf` for configuration files and `.tfvars` for variable value files. This allows Terraform and related tools (VS Code extension, linters, CI pipelines) to recognise and process them correctly.

```
main.tf
variables.tf
outputs.tf
terraform.tfvars
production.tfvars
```

Never use `.hcl` for Terraform config files — that extension is for other HashiCorp tools (Packer, Consul, etc.).

---

## 2. Formatting

Always format your files before committing. Consistent formatting improves readability, reduces noise in diffs, and is enforced in most professional teams via CI.

```bash
terraform fmt             # format current directory
terraform fmt -recursive  # include subdirectories
terraform fmt -check      # fail if files are not formatted (use in CI)
```

Follow the HCL Style Guide:
- 2-space indentation
- Aligned `=` signs on consecutive lines
- Opening brace on the same line
- snake_case for all names

---

## 3. Organisation

Separate concerns across files rather than putting everything in one `main.tf`. The standard convention:

| File | Contains |
|---|---|
| `main.tf` | Core resource definitions |
| `variables.tf` | All `variable` blocks |
| `outputs.tf` | All `output` blocks |
| `providers.tf` | `terraform` and `provider` blocks |
| `locals.tf` | `locals` blocks (for larger configs) |
| `terraform.tfvars` | Variable values for the default environment |
| `README.md` | Purpose, usage, inputs, outputs |

For larger projects, group related resources into **modules** with their own folder structure.

---

## 4. Commenting and Documentation

Use `#` comments to explain non-obvious decisions inside blocks. Include a `README.md` at the root of every module describing its purpose, inputs, and outputs.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Ubuntu 22.04 LTS — us-east-1
  instance_type = "t2.micro"              # free tier eligible

  # force replacement if the AMI changes
  lifecycle {
    create_before_destroy = true
  }
}
```

Comment the *why*, not the *what* — the code itself shows what it does.

---

## 5. Avoid Hardcoding Values

Use variables for anything that might change between environments (region, instance size, bucket names, CIDRs). Hardcoded values make configs inflexible and difficult to reuse.

```hcl
# avoid
resource "aws_instance" "web" {
  instance_type = "t2.micro"
  ami           = "ami-0c55b159cbfafe1f0"
}

# better
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

resource "aws_instance" "web" {
  instance_type = var.instance_type
  ami           = var.ami_id
}
```

---

## 6. Never Store Secrets in `.tf` Files

Do not hardcode passwords, API keys, or tokens in configuration files. These end up in version control and the state file.

```hcl
# never do this
resource "aws_db_instance" "main" {
  password = "supersecret123"
}

# do this instead — pass via environment variable or secrets manager
variable "db_password" {
  type      = string
  sensitive = true
}
```

Mark sensitive variables with `sensitive = true` to suppress them from plan/apply output. Use AWS Secrets Manager, SSM Parameter Store, or HashiCorp Vault for secrets at scale.

---

## 7. Always Use Remote State for Teams

The default local `terraform.tfstate` file is fine for learning but not for team use. Use a remote backend so state is shared, locked, and backed up.

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"  # enables state locking
    encrypt        = true
  }
}
```

Never commit `terraform.tfstate` or `terraform.tfstate.backup` to version control. Add them to `.gitignore`.

---

## 8. Pin Provider and Module Versions

Always specify version constraints for providers and modules. Unpinned versions can break configs when new versions are released.

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # allows 5.x, blocks 6.0
    }
  }
}
```

Version constraint operators:
| Operator | Meaning |
|---|---|
| `= 5.0.0` | Exact version only |
| `>= 5.0` | 5.0 or higher |
| `~> 5.0` | 5.x only (most common) |
| `>= 5.0, < 6.0` | Range |

---

## 9. Use `terraform plan` Before Every Apply

Never run `terraform apply` without reviewing the plan first. Always check for unexpected destructions (`-`) before confirming.

```bash
terraform plan -out=plan.out   # save the plan
terraform apply plan.out       # apply exactly what was reviewed
```

In CI/CD pipelines, save the plan as an artifact and apply the saved file — this guarantees what was approved is what gets applied.

---

## 10. Use `.gitignore` for Terraform Projects

Prevent sensitive or generated files from being committed:

```gitignore
# local state
*.tfstate
*.tfstate.backup
.terraform/

# variable files that may contain secrets
*.tfvars

# crash logs
crash.log

# plan files
*.tfplan
```

Keep `terraform.tfvars.example` in version control as a template (with no real values) so others know what variables are needed.

---

## 11. Use `locals` to Avoid Repetition

If the same expression appears in multiple places, extract it into a `local` value. Reduces errors and makes changes easier.

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "web" {
  tags = local.common_tags
}

resource "aws_s3_bucket" "data" {
  tags = local.common_tags
}
```

---

## 12. Validate Before Applying

Make `fmt → validate → plan` a habit before every apply:

```bash
terraform fmt       # fix formatting
terraform validate  # check for errors without hitting APIs
terraform plan      # preview changes
terraform apply     # execute
```

---

## 13. Managing Sensitive Data and Secrets (4h)

### Mark variables as sensitive

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

This suppresses the value in `plan` and `apply` output. It does **not** encrypt the value in state.

### Mark outputs as sensitive

```hcl
output "connection_string" {
  value     = "postgres://${var.db_user}:${var.db_password}@${aws_db_instance.main.endpoint}"
  sensitive = true
}
```

### HashiCorp Vault integration (4h)

Vault is HashiCorp's secrets management tool. Terraform can read secrets from Vault at plan/apply time rather than storing them in `.tf` files or state:

```hcl
provider "vault" {
  address = "https://vault.example.com"
}

data "vault_generic_secret" "db" {
  path = "secret/database"
}

resource "aws_db_instance" "main" {
  password = data.vault_generic_secret.db.data["password"]
}
```

**Why Vault?** Secrets fetched from Vault are dynamic — they can be rotated without changing Terraform config, and they're not stored in your state file.

### Other secrets approaches

| Method | How |
|---|---|
| Environment variables | `TF_VAR_db_password=...` at runtime — not stored in files |
| AWS Secrets Manager | Use `aws_secretsmanager_secret_version` data source |
| SSM Parameter Store | Use `aws_ssm_parameter` data source |
| HashiCorp Vault | Use `vault_generic_secret` data source |

The key rule: **secrets should never appear in `.tf` files, `.tfvars` files committed to git, or plan output.**

---

## Exam Focus Areas (Associate 004)

- `terraform fmt` — formatting, `-check` flag for CI (3g)
- Sensitive variable/output handling — `sensitive = true` (4c)
- Why secrets must not be in `.tf` files or committed state (4h)
- Vault as the HashiCorp-native secrets management solution (4h)
- Remote state + encryption for protecting sensitive state values (6b, 6c)
- `.gitignore` essentials for Terraform projects
