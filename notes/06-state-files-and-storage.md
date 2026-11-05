# Terraform State Files and Storage Options

**Exam Objectives Covered:** 2d, 6a, 6b, 6c, 6d

## What Is State?

Terraform uses a state file (`terraform.tfstate`) to map your configuration to real-world infrastructure. It records what resources exist, their attributes, and dependencies between them.

Without state, Terraform cannot:
- Know what it already created
- Detect drift between config and reality
- Determine what needs to change on the next apply

A backup of the previous state is always saved as `terraform.tfstate.backup`.

---

## What's Inside a State File

State files are JSON. They contain:
- Resource type, name, and provider
- All attributes of every managed resource (IDs, IPs, ARNs, etc.)
- Sensitive values **in plaintext** — passwords, keys, tokens

> **Never commit state files to git.** Add `*.tfstate` and `*.tfstate.backup` to `.gitignore`.

---

## Local State (Default)

State is stored in `terraform.tfstate` in the working directory.

```
project/
├── main.tf
├── terraform.tfstate        ← created after first apply
└── terraform.tfstate.backup ← previous state (auto-created)
```

**Suitable for:** learning, solo projects, short-lived labs  
**Not suitable for:** teams, production, any shared environment

**Problems with local state:**
- Only exists on one machine
- No locking — two applies at once can corrupt state
- Easy to lose or accidentally delete

---

## Remote State

Remote backends store state in a shared, durable location. This is the standard for any team or production environment.

### Configuring a Backend

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-tfstate"
    key            = "prod/networking/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Run `terraform init` after adding or changing a backend to migrate state.

---

## Storage Options

### S3 + DynamoDB (AWS)

Most common for AWS-based teams.

| Component | Purpose |
|---|---|
| S3 bucket | Stores the state file |
| DynamoDB table | Provides state locking |
| Server-side encryption | Protects sensitive values at rest |

```hcl
terraform {
  backend "s3" {
    bucket         = "tfstate-bucket"
    key            = "env/component/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
```

### Azure Blob Storage

Standard for Azure teams.

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

### Google Cloud Storage (GCS)

Standard for GCP teams.

```hcl
terraform {
  backend "gcs" {
    bucket = "tfstate-bucket"
    prefix = "prod/networking"
  }
}
```

### Terraform Cloud / HCP Terraform

Fully managed backend — no bucket or locking setup required.

```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "prod-networking"
    }
  }
}
```

**Benefits:** built-in locking, versioned state history, access controls, audit logs, remote runs.

### Local (Default)

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

No configuration needed — this is the default when no backend block is specified.

---

## State Locking

Locking prevents two applies from running simultaneously and corrupting state.

| Backend | Locking Mechanism |
|---|---|
| S3 | DynamoDB table |
| Azure Blob | Native blob leasing |
| GCS | Native object locking |
| Terraform Cloud | Built-in |
| Local | None |

If a lock is stuck (e.g., after a crash), use:
```bash
terraform force-unlock <LOCK_ID>
```

---

## Key State Commands

```bash
terraform state list              # list all resources tracked in state
terraform state show <resource>   # show full attributes of a resource
terraform state mv <old> <new>    # rename a resource in state
terraform state rm <resource>     # stop tracking a resource (does NOT destroy it)
terraform import <resource> <id>  # import existing infra into state
terraform refresh                 # sync state with real infrastructure (deprecated)
terraform apply -refresh-only     # preferred replacement for terraform refresh
```

---

## State and Sensitive Data

State stores sensitive values (passwords, private keys, connection strings) in plaintext JSON.

Best practices:
- Use a remote backend with encryption at rest
- Restrict access to the state bucket/container via IAM policies
- Never print state output in CI/CD logs
- Never commit state files to version control

---

## Resource Drift (6d)

**Drift** occurs when the real-world state of a resource no longer matches what is recorded in the Terraform state file. This happens when someone makes a change outside of Terraform (e.g., manually resizing an instance in the AWS console, or another tool modifying a tag).

### How Terraform detects drift

During `terraform plan`, Terraform calls provider APIs to refresh the actual state of each resource and compares it to the state file. Any differences are shown in the plan output.

### Handling drift

**Option 1: Let Terraform fix it (most common)**

Run `terraform plan` — Terraform will show the drift as a diff and propose changes to bring the real resource back in line with your config. Then `terraform apply` to enforce your config.

**Option 2: Update your config to match reality**

If the manual change was intentional and you want to keep it, update your `.tf` files to reflect the new desired state, then run `terraform apply`.

**Option 3: Refresh-only plan**

Update the state file to reflect current reality without making any infrastructure changes. This is useful to sync state after manual changes you want to keep:

```bash
terraform plan -refresh-only    # preview what the state refresh would change
terraform apply -refresh-only   # update state to match real-world, no infra changes
```

**Option 4: Remove a resource from state without destroying it**

If a resource was deleted outside Terraform and you want Terraform to stop tracking it:

```bash
terraform state rm aws_instance.web
```

This removes it from state. The resource itself (if it still exists) is no longer managed by Terraform.

### `terraform refresh` (deprecated)

The old way to sync state. Replaced by `-refresh-only`:

```bash
terraform refresh          # deprecated — updates state without prompting
terraform apply -refresh-only  # preferred — shows a plan first
```

---

## Workspaces and State

Each Terraform workspace has its own state file. This allows one configuration to manage multiple environments.

```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
```

State files are stored as:
```
s3://bucket/key/env:/dev/terraform.tfstate
s3://bucket/key/env:/prod/terraform.tfstate
```

> Workspaces are convenient for simple cases, but separate directories per environment are preferred for complex multi-team setups.

---

## Exam Focus Areas (Associate 004)

- Purpose of state and what happens if it's lost or corrupted
- `terraform.tfstate` and `terraform.tfstate.backup`
- Why remote backends are required for teams
- State locking — what it prevents and how it works per backend
- `terraform state` subcommands and when to use each
- `-refresh-only` flag replacing the deprecated `terraform refresh`
- Sensitive data in state and how to protect it
