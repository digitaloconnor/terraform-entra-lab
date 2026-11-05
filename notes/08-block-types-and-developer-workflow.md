# Terraform Block Types & Developer Workflow

**Exam Objectives Covered:** 2a, 2b, 2d, 3a, 3b, 3c, 3d, 3e, 3g, 4a, 4b, 4c, 4f

> **Related notes:** `03-basic-commands.md` (CLI reference) · `07-terraform-workflow.md` (workflow detail)  
> This note focuses on what you *write* — the block types — and how the full developer loop hangs together.

---

## The Developer Loop at a Glance

```
Write .tf files  →  terraform init  →  terraform fmt  →  terraform validate  →  terraform plan  →  terraform apply
     ↑                                                                                                    |
     └───────────────────────────── iterate based on plan output ───────────────────────────────────────┘
```

Each stage has a clear purpose:

| Stage | Command | Makes Changes? | Contacts Provider? |
|---|---|---|---|
| Write | (editor) | Files only | No |
| Initialise | `terraform init` | Downloads plugins | Registry only |
| Format | `terraform fmt` | Reformats files | No |
| Validate | `terraform validate` | No | No |
| Plan | `terraform plan` | No | Yes (reads real state) |
| Apply | `terraform apply` | Yes — real infra | Yes |

---

## HCL Block Types

Every `.tf` file is made of **blocks**. Each block has a type, optional labels, and a body inside `{}`.

```
block_type  "label_1"  "label_2"  {
  argument = value
}
```

There are eight block types you need to know for the exam.

---

### 1. `terraform` block

Configures Terraform itself — required version, backend, and which providers to use.

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "my-tfstate"
    key    = "prod/terraform.tfstate"
    region = "eu-west-1"
  }
}
```

- `required_version` — constrains the Terraform CLI version
- `required_providers` — pins provider sources and versions (written to `.terraform.lock.hcl` after `init`)
- `backend` — where state is stored (omit for local default)

**Exam tip:** Only one `terraform` block is allowed per configuration.

---

### 2. `provider` block

Configures a provider (AWS, Azure, GCP, etc.). Providers are plugins that translate your config into API calls.

```hcl
provider "aws" {
  region  = "eu-west-1"
  profile = "default"
}
```

- The label (`"aws"`) must match a provider declared in `required_providers`
- Multiple provider blocks of the same type are allowed using **aliases**

```hcl
provider "aws" {
  alias  = "us"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}
```

Reference an aliased provider in a resource:

```hcl
resource "aws_instance" "web_eu" {
  provider      = aws.eu
  ami           = "ami-0abc12345"
  instance_type = "t2.micro"
}
```

---

### 3. `resource` block

The most common block. Declares a piece of infrastructure to create and manage.

```hcl
resource "aws_instance" "web" {        # type = "aws_instance", name = "web"
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "web-server"
  }
}
```

- **Two labels required:** resource type (`aws_instance`) and local name (`web`)
- Local name is used only inside Terraform — not the real cloud resource name
- Reference this resource elsewhere as `aws_instance.web`
- Reference a specific attribute as `aws_instance.web.id`

**Resource addressing format:**
```
<resource_type>.<local_name>.<attribute>
aws_instance.web.id
aws_vpc.main.cidr_block
```

---

### 4. `data` block

Reads information from existing infrastructure **without creating or managing it**. Think of it as a read-only lookup.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]   # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}
```

Reference the result:

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id    # ← data source result
  instance_type = "t2.micro"
}
```

**Key distinction:**

| `resource` | `data` |
|---|---|
| Creates and manages infrastructure | Reads existing infrastructure |
| Tracked in state | Not tracked in state |
| Terraform controls lifecycle | External system controls it |
| Referenced as `resource_type.name` | Referenced as `data.resource_type.name` |

---

### 5. `variable` block

Declares an input variable — a value that can be passed in at runtime.

```hcl
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}
```

**Optional arguments:**

| Argument | Purpose |
|---|---|
| `type` | Enforces the data type (string, number, bool, list, map, set, object, tuple) |
| `description` | Documents what the variable is for |
| `default` | Makes the variable optional — omit it to require the user to provide a value |
| `sensitive` | Hides the value from plan/apply output |
| `validation` | Custom validation rule with an error message |

Reference in config:

```hcl
resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

**Ways to supply variable values (highest precedence wins):**

```
default in variable block          ← lowest
TF_VAR_<name> environment variable
terraform.tfvars file
*.auto.tfvars files (alphabetical)
-var-file flag
-var flag                          ← highest
```

---

### 6. `output` block

Exports a value from your configuration — visible after `apply` and accessible to other modules.

```hcl
output "instance_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of the web server"
}
```

View outputs after apply:

```bash
terraform output              # all outputs
terraform output instance_ip  # specific output
terraform output -json        # machine-readable
```

Optional arguments:

| Argument | Purpose |
|---|---|
| `value` | The value to export (required) |
| `description` | Documents the output |
| `sensitive` | Hides value from terminal output |
| `depends_on` | Explicit dependency (rare — use when implicit isn't enough) |

---

### 7. `locals` block

Defines local values — named expressions computed once and reused across the configuration. Think of them as intermediate variables internal to the module.

```hcl
locals {
  env         = "production"
  name_prefix = "${var.project}-${local.env}"
  common_tags = {
    Environment = local.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}
```

Reference with `local.<name>` (no "s"):

```hcl
resource "aws_instance" "web" {
  tags = local.common_tags
}
```

**When to use locals vs variables:**

| `variable` | `locals` |
|---|---|
| Value comes from outside (user, CI, tfvars) | Value computed inside the config |
| Can be overridden at runtime | Fixed at plan time |
| Declared with `variable {}` | Declared with `locals {}` |
| Referenced as `var.<name>` | Referenced as `local.<name>` |

---

### 8. `module` block

Calls a reusable module — a group of resources packaged together.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = var.vpc_name
  cidr = "10.0.0.0/16"
}
```

- `source` is required — can be a registry path, local path (`./modules/vpc`), or Git URL
- `version` pins the module version (registry modules only)
- Other arguments are the module's input variables

Reference a module's outputs:

```hcl
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnets[0]
}
```

Run `terraform init` whenever you add or change a module source.

---

## How Blocks Reference Each Other

```
variable "region" {}          → var.region
                                  ↓
provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {}    → data.aws_ami.ubuntu.id
                                  ↓
resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
}
                                  ↓
output "ip" {
  value = aws_instance.web.public_ip
}
```

Terraform reads these references and builds a **dependency graph** automatically. Resources with no dependency on each other are created in parallel; dependent ones are created in order.

---

## Implicit vs Explicit Dependencies

**Implicit** (preferred): Terraform detects dependencies from attribute references.

```hcl
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id    # Terraform knows: create VPC first
}
```

**Explicit** (`depends_on`): Use only when there is a real dependency that isn't expressed through an attribute reference.

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  depends_on = [aws_iam_role_policy.web_policy]   # role must exist before instance
}
```

---

## Typical File Layout

Terraform doesn't require specific file names — it reads all `.tf` files in the directory. Convention:

| File | Contents |
|---|---|
| `main.tf` | Resource blocks (the core config) |
| `variables.tf` | All `variable` blocks |
| `outputs.tf` | All `output` blocks |
| `providers.tf` | `terraform` and `provider` blocks |
| `locals.tf` | `locals` block (optional, for larger configs) |
| `terraform.tfvars` | Variable values (not committed if sensitive) |

For small labs, putting everything in `main.tf` is fine.

---

## Quick Command Reference (Write → Apply)

```bash
# 1. Write your .tf files in any editor

# 2. Initialise (download providers, modules, set up backend)
terraform init

# 3. Format files to canonical style
terraform fmt

# 4. Check for syntax/logic errors (offline — no provider calls)
terraform validate

# 5. Preview changes (contacts provider to compare real state)
terraform plan
terraform plan -out=tfplan          # save plan for exact replay

# 6. Apply
terraform apply                     # prompts for 'yes'
terraform apply tfplan              # apply the exact saved plan
terraform apply -auto-approve       # skip prompt (pipelines only)

# 7. Inspect results
terraform output
terraform show

# 8. Clean up (lab/dev)
terraform destroy
```

---

## Exam Focus Areas

- The **eight block types** and what each one does: `terraform`, `provider`, `resource`, `data`, `variable`, `output`, `locals`, `module`
- `resource` vs `data` — resource creates and manages; data only reads
- `variable` vs `locals` — variables come from outside; locals are computed inside
- How to **reference** each block type: `var.x`, `local.x`, `data.type.name.attr`, `module.name.output`, `resource_type.name.attr`
- Implicit dependencies through attribute references vs explicit `depends_on`
- The role of `terraform init` in downloading providers and modules
- `terraform validate` is offline; `terraform plan` contacts providers
- Conventional file layout (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`)
- Variable precedence order (default → env var → tfvars → auto.tfvars → -var-file → -var)
