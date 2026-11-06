# Terraform Cheat Sheet

**Exam Objectives Covered:** 2a, 2b, 2d, 3a, 3b, 3c, 3d, 3e, 3f, 3g, 4h, 7b

Quick reference for things I do often. Add new entries as sections below.

---

## Log in to Azure in VS Code

Do this at the start of each session, before running Terraform.

1. In VS Code, click **Terminal > New Terminal**.
2. Log in. A browser window opens, so sign in with the lab account:

   ```bash
   az login
   ```

3. Back in the terminal, pick the subscription from the list by typing its number and pressing Enter.
4. Copy the **Subscription ID** from the output.
5. Set the variable, replacing the placeholder with the ID you copied:

   ```bash
   export ARM_SUBSCRIPTION_ID=<subscription-id>
   ```

6. Go to the folder that holds your `.tf` files:

   ```bash
   cd <folder-with-tf-files>
   ```

7. Test it. This only reads and makes no changes in Azure:

   ```bash
   terraform plan
   ```

It worked if the plan runs without an authentication or `subscription_id` error.

**Shortcut for steps 4 and 5:** this sets the variable without any copying, using the subscription you just picked.

```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

### Good to know

| Check or problem | What to do |
|---|---|
| Am I in the right account? | Run `az account show` and check `user` and `tenantDisplayName`. It should be the lab, never the work tenant. |
| Is the variable set? | Run `echo $ARM_SUBSCRIPTION_ID`. It should print the ID. |
| Opened a new terminal tab | Repeat step 5. `export` only lasts for the terminal it was run in. |
| Error: `subscription_id` is required | The variable isn't set in this terminal, or its name is wrong. Repeat step 5. |
| Error: run `terraform init` | This is a new folder, or the providers changed. Run `terraform init`, then plan again. |
| Why `plan` and not `apply`? | `apply` can create real resources, which can cost money. `plan` tests the login safely. |

---

## Daily Terraform commands

Run these from the folder that holds your `.tf` files, in this order.

| Order | Command | What it does | Changes Azure? |
|---|---|---|---|
| 1 | `terraform init` | Sets up the folder and downloads providers. Needed for a new folder, or after changing providers, modules or the backend. | No |
| 2 | `terraform fmt` | Tidies the layout of your `.tf` files. | No, only your files |
| 3 | `terraform validate` | Checks the code is valid, without connecting to Azure. | No |
| 4 | `terraform plan` | Previews what would be created, changed or destroyed. | No |
| 5 | `terraform apply` | Shows the plan, then makes the changes after you type `yes`. | **Yes** |
| 6 | `terraform destroy` | Shows what will be removed, then deletes it after you type `yes`. | **Yes** |

### Reading the plan

| Symbol | Meaning |
|---|---|
| `+` | Create |
| `~` | Change in place |
| `-` | Destroy |
| `-/+` | Destroy, then create a replacement |

The summary line tells you the totals, for example `Plan: 2 to add, 0 to change, 0 to destroy.` Read it before typing `yes`.

### Good to know

| Situation | What to do |
|---|---|
| Is it safe to run `init` again? | Yes. It won't touch your resources or your code. |
| See what Terraform is managing | Run `terraform state list`. |
| `fmt` printed nothing | Your files were already tidy, so nothing needed changing. |
| `validate` passed but `plan` failed | `validate` only checks the code. `plan` also needs a working Azure login, so check the login steps above. |

---

## Set up GitHub credentials

Do this once per computer. Unlike the Azure variable, it stays set when you open a new terminal or restart.

**Check first, as you may not need the rest:**

```bash
gh auth status
```

If it says `Logged in to github.com`, skip to step 5.

1. In VS Code, click **Terminal > New Terminal**.
2. Start the sign-in:

   ```bash
   gh auth login
   ```

3. Answer the questions using the arrow keys and Enter:

   | Question | Answer |
   |---|---|
   | Where do you use GitHub? | GitHub.com |
   | Preferred protocol for Git operations? | HTTPS |
   | Authenticate Git with your GitHub credentials? | Yes |
   | How would you like to authenticate? | Login with a web browser |

4. Copy the one-time code shown in the terminal and press Enter. Paste the code into the browser page that opens, then click **Authorize**.
5. Check your name and email. These appear on every commit:

   ```bash
   git config --global user.name
   ```

   ```bash
   git config --global user.email
   ```

6. If either one is blank or wrong, set it:

   ```bash
   git config --global user.name "<your-name>"
   ```

   ```bash
   git config --global user.email "<your-email>"
   ```

7. Test it. This should show your repo's details:

   ```bash
   gh repo view digitaloconnor/terraform-entra-lab
   ```

### Keep out of GitHub

Add these to `.gitignore` in your repo, because state and variable files can contain secrets.

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
```

**Do commit `.terraform.lock.hcl`.** It records the exact provider versions, so every run uses the same ones.

### Good to know

| Check or problem | What to do |
|---|---|
| Git asks for a password | Run `gh auth setup-git`, then try again. GitHub doesn't accept your account password for Git. |
| Email shows on public commits | To hide it, use the `noreply` address from GitHub **Settings > Emails**. This only affects new commits. |
| Sign-in has more access than needed | To remove the right to delete repos, run `gh auth refresh --remove-scopes delete_repo`. |
| Accidentally committed a secret | Change the secret straight away. Deleting the file in a later commit leaves it in the Git history. |

---

## Exam Focus Areas (Associate 004)

- Providers need credentials to reach a platform, and these should come from outside the code, such as environment variables or a CLI login (2b).
- `terraform init` must run before `plan` in a new working directory (3b).
- `terraform plan` previews changes without making them (3d). `terraform apply` makes them (3e).
- The core workflow is write, plan, apply (3a).
- `terraform validate` checks that the configuration is valid but does not check real infrastructure (3c).
- `terraform destroy` removes everything the configuration manages (3f).
- `terraform fmt` applies the standard style to your files (3g).
- `terraform state list` shows the resources Terraform is tracking (7b).
- `.terraform.lock.hcl` records provider versions and should be committed (2a).
- State files can hold sensitive values in plain text, so don't commit them to Git (2d, 4h).
