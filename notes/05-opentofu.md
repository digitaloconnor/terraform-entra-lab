# OpenTofu

**Exam Objectives Covered:** None — this is ecosystem context only. OpenTofu is not tested on the Associate 004 exam.

## What is OpenTofu?

OpenTofu is an open-source, community-driven Infrastructure as Code tool and a **drop-in replacement for Terraform**. It is governed by the **Linux Foundation** and is free to use with no licensing restrictions.

Website: https://opentofu.org

---

## Why Does OpenTofu Exist?

In August 2023, HashiCorp changed Terraform's licence from the open-source **Mozilla Public License v2 (MPL 2.0)** to the **Business Source Licence (BUSL 1.1)**. Under BUSL, Terraform is no longer truly open-source — companies building competing products cannot use it freely.

In response, a group of companies (Gruntwork, Spacelift, Harness, Env0, Scalr, and others) forked Terraform at the last MPL-licenced version and created OpenTofu under the Linux Foundation. It is licenced under **MPL 2.0** and committed to remaining open-source permanently.

### Timeline

| Date | Event |
|---|---|
| Aug 2023 | HashiCorp switches Terraform to BUSL licence |
| Sep 2023 | OpenTofu fork announced, hosted under Linux Foundation |
| Jan 2024 | OpenTofu 1.6 — first stable GA release |
| May 2024 | OpenTofu 1.7 — state encryption introduced |
| Oct 2024 | OpenTofu 1.8 — early variable/local evaluation |
| Jan 2025 | OpenTofu 1.9 — provider `for_each`, `-exclude` flag |

---

## OpenTofu vs Terraform

### What's the same
- HCL syntax is identical
- Same core workflow: `init → plan → apply → destroy`
- Same CLI commands and flags
- Compatible with the same providers and modules (Terraform Registry)
- State file format is compatible
- Existing Terraform configurations work without changes

### Where OpenTofu is ahead

| Feature | OpenTofu | Terraform |
|---|---|---|
| **State encryption** | Built-in (v1.7+) | Not available |
| **Provider `for_each`** | Supported (v1.9+) | Not available |
| **Early variable evaluation** | Supported (v1.8+) | Not available |
| **`-exclude` flag** | Supported (v1.9+) | Not available |
| **Licence** | MPL 2.0 (open-source) | BUSL 1.1 (restricted) |
| **Governance** | Linux Foundation / community | HashiCorp / IBM |

### Where Terraform is ahead

| Feature | Terraform | OpenTofu |
|---|---|---|
| **HCP Terraform** | Full integration | Not applicable |
| **Enterprise features** | Terraform Enterprise | No equivalent |
| **HashiCorp support** | Commercial support available | Community only |

---

## Key Features Unique to OpenTofu

### State Encryption (v1.7+)
Built-in client-side encryption of the state file. Supports multiple key providers:
- PBKDF2 (passphrase-based)
- AWS KMS
- GCP KMS
- OpenBao (open-source Vault fork)

```hcl
terraform {
  encryption {
    key_provider "pbkdf2" "my_key" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "my_method" {
      keys = key_provider.pbkdf2.my_key
    }

    state {
      method = method.aes_gcm.my_method
    }
  }
}
```

### Provider `for_each` (v1.9+)
Dynamically generate provider configurations — useful for multi-region or multi-account setups without repetitive provider blocks.

```hcl
variable "regions" {
  default = ["us-east-1", "eu-west-1"]
}

provider "aws" {
  for_each = toset(var.regions)
  alias    = each.key
  region   = each.key
}
```

### Early Variable/Local Evaluation (v1.8+)
Variables and locals can now be used in more places (like backend configuration) without workarounds.

### `-exclude` Flag (v1.9+)
The inverse of `-target` — exclude specific resources from a plan or apply instead of targeting specific ones.

```bash
tofu plan -exclude=aws_instance.web
```

---

## Installing OpenTofu

### macOS (Homebrew)
```bash
brew install opentofu
tofu version
```

### Verify
```bash
tofu version
# OpenTofu v1.9.x on darwin_arm64
```

OpenTofu uses the `tofu` command instead of `terraform`. All subcommands are identical:

```bash
tofu init
tofu plan
tofu apply
tofu destroy
```

---

## Migrating from Terraform to OpenTofu

Migration is designed to be safe and reversible:

1. **Back up your state file** — copy `terraform.tfstate` somewhere safe
2. **Install OpenTofu** — `brew install opentofu`
3. **Run `tofu init`** — in your existing Terraform project directory
4. **Run `tofu plan`** — verify no unexpected changes
5. **Test with a small apply** — validate before fully switching over

No changes to `.tf` files are required for basic migration. The state file format is compatible.

---

## Should You Learn OpenTofu or Terraform?

For the **HashiCorp Terraform Associate 004 exam** — learn Terraform. The exam is HashiCorp-specific and tests Terraform CLI, HCP Terraform, and HashiCorp tooling.

For **real-world use** — OpenTofu is a strong choice if you want to avoid BUSL licence restrictions or need features like state encryption.

**The good news:** because the syntax, commands, and concepts are nearly identical, knowing one means you know the other. Skills are fully transferable.

---

## Exam Relevance

OpenTofu is **not tested** on the Terraform Associate 004 exam. However, understanding why it exists (BUSL licence change) demonstrates awareness of the Terraform ecosystem and may come up in conversation at work or in interviews.
