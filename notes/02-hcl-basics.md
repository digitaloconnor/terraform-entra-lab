# HashiCorp Configuration Language (HCL) — Basics

**Exam Objectives Covered:** 4a, 4b, 4c, 4d, 4e, 4f, 4g

## What is HCL?

HCL is the language used to write Terraform configuration files. It is:
- **Declarative** — describe what you want, not how to do it
- **Human-readable** — designed to be easy to read and write
- **JSON-compatible** — valid JSON is valid HCL (but HCL is preferred)

Files use the `.tf` extension. A typical project has multiple `.tf` files in one directory.

---

## HCL Style Guide

Not enforced by Terraform (except where noted), but these conventions are standard across the community and what `terraform fmt` will apply automatically.

---

### Indentation — 2 spaces

Always use 2 spaces per level. Never use tabs.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  network_interface {
    device_index = 0
    network_id   = aws_network_interface.main.id
  }
}
```

---

### Naming — snake_case

Use `snake_case` for all resource names, variable names, output names, and locals. Never use hyphens or camelCase.

```hcl
# correct
resource "aws_instance" "web_server" {}
variable "instance_type" {}
output "public_ip_address" {}

# incorrect
resource "aws_instance" "webServer" {}
resource "aws_instance" "web-server" {}
```

---

### Align Equal Signs on Consecutive Lines

When multiple arguments appear together, align the `=` signs to the same column. `terraform fmt` does this automatically.

```hcl
# correct
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"
}

# incorrect
resource "aws_instance" "web" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name = "my-key"
}
```

---

### Comments

Comments are not required but are helpful for explaining the purpose of blocks and non-obvious arguments.

```hcl
# This is a single line comment — preferred style

// This also works as a single line comment

/* This is a
   multi-line comment */
```

`#` is the community standard and what `terraform fmt` expects. Use inline comments to explain non-obvious values:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Ubuntu 22.04 LTS in us-east-1
  instance_type = "t2.micro"              # free tier eligible
}
```

---

### Opening Brace on the Same Line

The opening `{` always goes on the same line as the block declaration, never on a new line.

```hcl
# correct
resource "aws_instance" "web" {
}

# incorrect
resource "aws_instance" "web"
{
}
```

---

### Blank Lines Between Blocks

Separate top-level blocks with a single blank line. Use blank lines inside a block to group related arguments logically.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "web-server"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}
```

---

### Argument Order Within a Block

Follow this order for consistency:
1. Meta-arguments first (`count`, `for_each`, `provider`, `depends_on`)
2. Required arguments
3. Optional arguments
4. `lifecycle` block last

```hcl
resource "aws_instance" "web" {
  count = 2                          # 1. meta-argument

  ami           = "ami-abc123"       # 2. required
  instance_type = "t2.micro"        # 2. required

  key_name = "my-key"               # 3. optional

  lifecycle {                        # 4. lifecycle last
    prevent_destroy = true
  }
}
```

---

### `terraform fmt` Handles Most of This

Run `terraform fmt` before every commit. It automatically fixes indentation, `=` alignment, and brace spacing. Think of it like `prettier` for HCL.

```bash
terraform fmt             # format current directory
terraform fmt -recursive  # format all subdirectories
terraform fmt -check      # check without modifying (useful in CI)
```

---

## Block Syntax

Everything in HCL is a **block**. The basic structure is:

```hcl
<block_type> "<type_label>" "<name_label>" {
  argument = value
}
```

Example:
```hcl
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

- `resource` = block type
- `"aws_instance"` = resource type (from the AWS provider)
- `"web_server"` = your local name for this resource
- Everything inside `{}` = arguments (configuration for that resource)

---

## Block Types

| Block | Purpose |
|---|---|
| `resource` | Creates and manages an infrastructure object |
| `data` | Reads data from an existing external resource (read-only) |
| `variable` | Defines an input parameter for your config |
| `output` | Exposes a value after apply (like a return value) |
| `locals` | Defines computed intermediate values (like a local variable) |
| `module` | Calls a reusable module |
| `provider` | Configures a provider (AWS, Azure, etc.) |
| `terraform` | Settings: backend, required providers, Terraform version |

---

## Data Types

```hcl
# String
name = "my-server"

# Number
count = 3

# Boolean
enabled = true

# List
availability_zones = ["us-east-1a", "us-east-1b"]

# Map
tags = {
  Name        = "web-server"
  Environment = "dev"
}
```

---

## Variables

### Declaring a variable
```hcl
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}
```

### Using a variable
```hcl
resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

### Variable types
- `string`
- `number`
- `bool`
- `list(<type>)`
- `set(<type>)`
- `map(<type>)`
- `object({...})`
- `tuple([...])`
- `any`

---

## Complex Types (4d)

### list vs set vs tuple

| Type | Ordered | Unique | Mixed types |
|---|---|---|---|
| `list` | Yes | No | No |
| `set` | No | Yes (no duplicates) | No |
| `tuple` | Yes | No | Yes |

```hcl
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "allowed_ports" {
  type    = set(number)
  default = [80, 443, 8080]
}
```

### object

A structured type with named attributes, each with its own type:

```hcl
variable "server_config" {
  type = object({
    instance_type = string
    volume_size   = number
    enable_monitoring = bool
  })
  default = {
    instance_type     = "t2.micro"
    volume_size       = 20
    enable_monitoring = true
  }
}
```

### map

Key-value pairs where all values share the same type:

```hcl
variable "environment_tags" {
  type = map(string)
  default = {
    dev  = "development"
    prod = "production"
  }
}
```

---

## Expressions and Functions (4e)

### Conditional expression

```hcl
instance_type = var.environment == "prod" ? "t3.large" : "t2.micro"
```

### for expression

```hcl
# Transform a list
output "upper_names" {
  value = [for name in var.names : upper(name)]
}

# Filter a list
output "long_names" {
  value = [for name in var.names : name if length(name) > 5]
}
```

### Common built-in functions

| Function | Example | Result |
|---|---|---|
| `length()` | `length(["a","b","c"])` | `3` |
| `toset()` | `toset(["a","b","a"])` | `{"a","b"}` |
| `tolist()` | `tolist(toset(["b","a"]))` | `["a","b"]` |
| `merge()` | `merge({a=1},{b=2})` | `{a=1,b=2}` |
| `lookup()` | `lookup(var.map,"key","default")` | value or default |
| `upper()` | `upper("hello")` | `"HELLO"` |
| `lower()` | `lower("HELLO")` | `"hello"` |
| `format()` | `format("server-%d", 1)` | `"server-1"` |
| `join()` | `join(",",["a","b"])` | `"a,b"` |
| `split()` | `split(",","a,b")` | `["a","b"]` |
| `flatten()` | `flatten([[1,2],[3]])` | `[1,2,3]` |
| `cidrsubnet()` | `cidrsubnet("10.0.0.0/16",8,1)` | `"10.0.1.0/24"` |

Test functions interactively with `terraform console`.

---

## Outputs

Expose values from your configuration after apply:

```hcl
output "instance_ip" {
  value       = aws_instance.web.public_ip
  description = "The public IP of the web server"
}
```

Mark sensitive outputs to suppress them from CLI output:

```hcl
output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}
```

View outputs with `terraform output`.

---

## Locals

Computed values you reference within a config (not exposed as outputs, not inputs):

```hcl
locals {
  env_prefix = "${var.environment}-${var.project}"
}

resource "aws_s3_bucket" "data" {
  bucket = "${local.env_prefix}-data"
}
```

---

## References & Expressions

### Referencing a resource attribute
```hcl
# Format: <resource_type>.<name>.<attribute>
aws_instance.web.public_ip
```

### String interpolation
```hcl
name = "server-${var.environment}"
```

### Referencing a variable
```hcl
var.instance_type
```

### Referencing a local
```hcl
local.env_prefix
```

### Referencing a data source
```hcl
data.aws_ami.ubuntu.id
```

---

## Data Sources

Read existing resources without managing them:

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
}
```

---

## Meta-Arguments

Special arguments available on any resource block:

| Meta-argument | Purpose |
|---|---|
| `count` | Create multiple instances of a resource |
| `for_each` | Create one resource per item in a map or set |
| `depends_on` | Explicit dependency when Terraform can't infer it |
| `provider` | Use a non-default provider configuration |
| `lifecycle` | Control create/destroy behaviour |

### `count` example
```hcl
resource "aws_instance" "server" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "server-${count.index}"
  }
}
```

### `for_each` example

`for_each` creates one resource per item in a map or set. Preferred over `count` when resources have distinct identities:

```hcl
variable "buckets" {
  default = {
    assets  = "us-east-1"
    backups = "eu-west-1"
  }
}

resource "aws_s3_bucket" "store" {
  for_each = var.buckets
  bucket   = each.key
  # each.value = "us-east-1" or "eu-west-1"
}
```

Each resource is addressed as `aws_s3_bucket.store["assets"]` — more stable than index-based `count`.

### `depends_on` example

Use when Terraform can't automatically detect a dependency:

```hcl
resource "aws_iam_role_policy_attachment" "attach" {
  depends_on = [aws_iam_role.role]
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
```

### `lifecycle` example
```hcl
resource "aws_instance" "web" {
  lifecycle {
    prevent_destroy       = true   # block accidental destroy
    create_before_destroy = true   # replace without downtime
    ignore_changes        = [tags] # don't track tag changes in state
  }
}
```

---

## Custom Validation Conditions (4g)

Add validation rules to variables to catch bad values before a plan runs:

```hcl
variable "instance_type" {
  type        = string
  description = "EC2 instance type"

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.small"], var.instance_type)
    error_message = "instance_type must be t2.micro, t3.micro, or t3.small."
  }
}
```

```hcl
variable "vpc_cidr" {
  type = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}
```

Multiple `validation` blocks are allowed on a single variable. The `condition` must be a boolean expression using `can()`, `contains()`, `regex()`, or other functions.

---

## Common File Naming Convention

| File | Purpose |
|---|---|
| `main.tf` | Primary resource definitions |
| `variables.tf` | All variable declarations |
| `outputs.tf` | All output declarations |
| `providers.tf` | Provider and terraform block |
| `terraform.tfvars` | Variable values (auto-loaded) |

Not enforced by Terraform — just a widely used convention.
