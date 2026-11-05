# Terraform — Basic Commands

**Exam Objectives Covered:** 3a, 3b, 3c, 3d, 3e, 3f, 3g, 7a, 7b, 7c

## Core Workflow

```
WRITE → INIT → PLAN → APPLY → DESTROY
```

---

## Essential Commands

### `terraform init`
Initialises the working directory. **Always run first.**
- Downloads required providers
- Sets up the backend
- Downloads modules

```bash
terraform init
```

Run again when you:
- Add a new provider
- Change backend configuration
- Add a module

---

### `terraform fmt`
Formats all `.tf` files to the canonical HCL style.

```bash
terraform fmt          # format current directory
terraform fmt -recursive  # format all subdirectories too
```

Run this before committing code.

---

### `terraform validate`
Checks your configuration for syntax errors and logical issues. Does **not** contact any APIs.

```bash
terraform validate
```

---

### `terraform plan`
Previews what Terraform will create, change, or destroy. Nothing is executed.

```bash
terraform plan
terraform plan -out=plan.out   # save the plan to a file
```

Reading plan output:
- `+` = will be created
- `-` = will be destroyed
- `~` = will be updated in-place
- `-/+` = will be destroyed and recreated

---

### `terraform apply`
Executes the plan and makes real changes to infrastructure.

```bash
terraform apply                    # prompts for confirmation
terraform apply -auto-approve      # skip confirmation (use carefully)
terraform apply plan.out           # apply a saved plan file
```

---

### `terraform destroy`
Destroys all resources managed by the current configuration.

```bash
terraform destroy
terraform destroy -auto-approve    # skip confirmation
```

**Exam tip:** `destroy` is equivalent to running `apply` with every resource marked for deletion.

---

### `terraform output`
Shows the values of output blocks after an apply.

```bash
terraform output                   # show all outputs
terraform output instance_ip       # show a specific output
terraform output -json             # output in JSON format
```

---

### `terraform show`
Shows the current state or a saved plan in human-readable format.

```bash
terraform show                     # show current state
terraform show plan.out            # show a saved plan
```

---

### `terraform state`
Inspect and manipulate the state file directly.

```bash
terraform state list               # list all resources in state
terraform state show aws_instance.web   # show details of one resource
terraform state mv <old> <new>     # rename a resource in state
terraform state rm <resource>      # remove a resource from state (doesn't destroy it)
```

---

### `terraform console`
Interactive REPL for evaluating expressions. Great for testing functions and references.

```bash
terraform console
> var.instance_type
> "t2.micro"
> length(["a", "b", "c"])
> 3
```

---

### `terraform import` (7a)

Brings existing infrastructure that was created outside of Terraform under Terraform management. Does **not** generate configuration — you must write the resource block yourself first.

```bash
terraform import aws_instance.web i-1234567890abcdef0
```

**Workflow:**
1. Write the resource block in your `.tf` file
2. Run `terraform import <resource_address> <real_resource_id>`
3. Run `terraform plan` — verify no unexpected changes
4. Commit the config

> Since Terraform 1.5, you can also use `import` blocks inside `.tf` files for declarative import.

```hcl
import {
  to = aws_instance.web
  id = "i-1234567890abcdef0"
}
```

---

### `terraform workspace`

Workspaces allow multiple state files from the same configuration — useful for dev/staging/prod isolation.

```bash
terraform workspace list              # list all workspaces
terraform workspace new dev           # create and switch to 'dev'
terraform workspace select prod       # switch to 'prod'
terraform workspace show              # display current workspace
terraform workspace delete dev        # delete a workspace (must not be current)
```

The default workspace is named `default`. Each workspace gets its own state file.

Reference the current workspace in config:

```hcl
resource "aws_instance" "web" {
  instance_type = terraform.workspace == "prod" ? "t3.large" : "t2.micro"
}
```

---

### `terraform graph`
Generates a visual dependency graph of your configuration (outputs DOT format).

```bash
terraform graph | dot -Tsvg > graph.svg
```

---

### `terraform providers`
Shows which providers are required and where they come from.

```bash
terraform providers
```

---

## Useful Flags

| Flag | Command | Purpose |
|---|---|---|
| `-auto-approve` | apply, destroy | Skip the yes/no confirmation |
| `-target=<resource>` | plan, apply | Only affect a specific resource |
| `-var="key=value"` | plan, apply | Pass a variable inline |
| `-var-file=<file>` | plan, apply | Load variables from a file |
| `-out=<file>` | plan | Save the plan to a file |
| `-refresh-only` | plan, apply | Update state to match real world, no changes |
| `-replace=<resource>` | plan, apply | Force replacement of a specific resource |

---

## Variable Precedence (lowest → highest)

```
TF_VAR_* env variables
  → terraform.tfvars
    → *.auto.tfvars (alphabetical order)
      → -var-file flag
        → -var flag  ← wins
```

Higher in the list = easier to override. The `-var` flag always wins.

---

## Environment Variables

| Variable | Purpose |
|---|---|
| `TF_LOG` | Enable logging: TRACE, DEBUG, INFO, WARN, ERROR |
| `TF_LOG_PATH` | Write logs to a file instead of stdout |
| `TF_VAR_<name>` | Set a Terraform input variable |
| `AWS_ACCESS_KEY_ID` | AWS credential (alternative to aws configure) |
| `AWS_SECRET_ACCESS_KEY` | AWS credential |
| `AWS_DEFAULT_REGION` | Default AWS region |

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
```

## Verbose Logging (7c)

Terraform uses `TF_LOG` to control log verbosity. Log levels from most to least verbose:

| Level | When to use |
|---|---|
| `TRACE` | Maximum detail — provider API calls, every internal step |
| `DEBUG` | Detailed diagnostic information |
| `INFO` | General operational messages |
| `WARN` | Warnings about potential issues |
| `ERROR` | Errors only |
| `OFF` | Disable logging |

```bash
# Log everything to a file
export TF_LOG=TRACE
export TF_LOG_PATH=./terraform-debug.log
terraform apply

# Clear logging
unset TF_LOG
```

You can also split provider logs from core Terraform logs:

```bash
export TF_LOG_CORE=INFO       # Terraform core logs
export TF_LOG_PROVIDER=TRACE  # Provider plugin logs only
```

**When to use verbose logging:**
- Debugging provider API errors
- Diagnosing authentication failures
- Investigating unexpected plan diffs
- Troubleshooting slow operations

---

## Day-to-Day Workflow

```bash
# 1. Write your .tf files
# 2. Initialise
terraform init

# 3. Format and validate
terraform fmt
terraform validate

# 4. Preview changes
terraform plan

# 5. Apply
terraform apply

# 6. When done / cleaning up
terraform destroy
```
