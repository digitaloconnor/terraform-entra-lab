# Terraform — Core Components & Benefits

**Exam Objectives Covered:** 1a, 1b, 1c, 2b

## What is Terraform?

Terraform is an open-source **Infrastructure as Code (IaC)** tool by HashiCorp. It lets you define, provision, and manage cloud infrastructure using declarative configuration files instead of clicking through a console.

---

## Core Benefits

| Benefit | What it means |
|---|---|
| **Infrastructure as Code** | Infrastructure is defined in files, stored in version control, reviewed like code |
| **Declarative** | You describe the *end state* you want — Terraform figures out how to get there |
| **Provider-agnostic** | Works with AWS, Azure, GCP, Kubernetes, and 1000+ providers from one tool |
| **Idempotent** | Running `apply` multiple times produces the same result — no duplicate resources |
| **Plan before apply** | Preview exactly what will change before anything is touched |
| **State tracking** | Terraform knows what it manages and can detect drift from real-world state |

---

## Core Components

### 1. Terraform CLI
The command-line tool you use to write, plan, and apply configurations. Installed locally on your machine.

### 2. Configuration Files (`.tf` files)
Written in HCL. Define the resources, variables, outputs, and providers that make up your infrastructure.

### 3. Providers
Plugins that let Terraform talk to external APIs (AWS, Azure, GitHub, etc.). Declared in your config and downloaded during `terraform init`.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### 4. Resources
The fundamental building block. Represents a single infrastructure object (an EC2 instance, an S3 bucket, a DNS record).

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

### 5. State File (`terraform.tfstate`)
A JSON file Terraform maintains to track what resources it manages and their current attributes. **Never edit this manually.**

- Stored locally by default
- Stored remotely (S3, HCP Terraform) for team use
- Used to calculate what changes need to be made on each `plan`

### 6. Backend
Where the state file is stored. Default is local. Remote backends (S3, HCP Terraform) enable team collaboration and state locking.

### 7. Modules
Reusable packages of Terraform configuration. A module is just a folder of `.tf` files. Every Terraform project is technically a module (the root module).

---

## Multi-Cloud, Hybrid Cloud, and Service-Agnostic Workflows (1c)

Terraform manages infrastructure across any combination of providers from a single tool and workflow. This is one of its core differentiators.

### How it works

Each provider is a plugin that translates Terraform's resource model into API calls for a specific platform. You can mix providers in one configuration:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "azurerm" {
  features {}
}

resource "aws_s3_bucket" "assets" {
  bucket = "my-assets"
}

resource "azurerm_resource_group" "main" {
  name     = "my-rg"
  location = "West Europe"
}
```

### Multi-cloud
Running workloads across AWS, Azure, GCP, or others simultaneously. A single Terraform config can provision and wire together resources from all three.

### Hybrid cloud
Managing both on-premises infrastructure (VMware, bare metal via providers) and cloud infrastructure with the same tool and workflow.

### Service-agnostic
Terraform providers exist for non-cloud services too — GitHub, Datadog, PagerDuty, Cloudflare, Kubernetes, databases. Anything with an API can have a provider. The same `init → plan → apply` workflow applies everywhere.

### Key exam point
Terraform does not require you to learn different tools per cloud. The HCL syntax, CLI commands, and workflow are identical regardless of which provider you use.

---

## IaC vs Traditional Infrastructure

| Traditional (ClickOps) | Infrastructure as Code |
|---|---|
| Manual, error-prone | Repeatable and consistent |
| No audit trail | Version controlled |
| Hard to replicate | Easily cloned across environments |
| Slow to scale | Automated and fast |

---

## Terraform vs Other IaC Tools

| Tool | Type | Cloud |
|---|---|---|
| Terraform | Declarative, multi-cloud | Any |
| CloudFormation | Declarative | AWS only |
| Ansible | Procedural, config mgmt | Any |
| Pulumi | Imperative (real code) | Any |

**Exam tip:** Terraform is *declarative* and *cloud-agnostic* — these two facts appear frequently.

---

## Exam Focus Areas (Associate 004)

- What IaC is and the problems it solves over manual/ClickOps approaches (1a)
- Benefits: declarative, idempotent, version-controlled, plan before apply (1b)
- Terraform's provider model as the mechanism for multi-cloud support (1c)
- The names and purposes of all 7 core components (CLI, config files, providers, resources, state, backend, modules)
- Terraform vs CloudFormation: Terraform is multi-cloud; CloudFormation is AWS-only (1c)
- Terraform vs Ansible: Terraform is declarative/IaC; Ansible is procedural/config mgmt
