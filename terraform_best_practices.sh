# ==================================================================================================
# 🧱 GCP Data Platform Infrastructure — Terraform Best Practices & Workflow Handbook
# --------------------------------------------------------------------------------------------------
# This handbook defines the standardized, automated, and scalable Data Platform workflow on GCP.
#
# 🏗️ Architecture Context:
# - Root Directory: C:\U\xxx\yyy\Terraform Infrastructure
# - Sandbox Project: gcp-terraform-tmp | Region: EU
# - Reusable Module: modules/data_platform_bigquery (Handles dataset, IAM, & FinOps labels)
# - Domain Configuration: domains/h1_gci_marketing (Implements raw_gci_marketing_prod)
# - Remote State: GCS Bucket (gs://gcp-terraform-tmp-tfstate-prasanna)
# - CI/CD: GitHub Actions (.github/workflows/terraform-ci.yml)
#
# 🔑 Core Versioning Rule:
# All commit messages MUST strictly follow: V[x.x.x] — [Task Description]
# Example: git commit -m "V1.0.4 — Domain State / Migrate H1 GCI Marketing State to GCS Remote Backend"
#
# Author: Prasanna
# Stack: Terraform + Google Cloud Platform (GCP) + GitHub Actions
# ==================================================================================================

# ==================================================================================================
# 🧭 Section 1: Directory Navigation & Working Context
# --------------------------------------------------------------------------------------------------
# ✅ What It Does:
#    Moves your PowerShell session into the target directory before executing commands.
#
# 📅 When to Use:
#    - Navigating to Root: For repository-wide commands (git, terraform fmt -recursive).
#    - Navigating to Domain: For infrastructure execution (terraform init, plan, apply).
#
# ⚠️ Common Mistake:
#    - Running 'terraform plan' or 'terraform apply' from the Root folder instead of a Domain folder.
# ==================================================================================================

# Project Root Navigation
cd "C:\Users\prasa\Root\Terraform Infrastructure"

# Specific Domain Navigation (Where main.tf execution lives)
cd "C:\Users\prasa\Root\Terraform Infrastructure\domains\h1_gci_marketing"


# ==================================================================================================
# 🔑 Section 2: GCP Authentication & CLI Configuration
# --------------------------------------------------------------------------------------------------
# ✅ What It Does:
#    Authenticates your local terminal with GCP and sets the default project context.
#
# 📅 When to Use:
#    - When setting up a new machine or when your token expires.
#    - If gcloud throws "You do not currently have an active account selected".
# ==================================================================================================

# Step 1: Login to Google Cloud via Browser
gcloud auth login

# Step 2: Set target sandbox project
gcloud config set project gcp-terraform-tmp

# ==================================================================================================
# 📁 Section 2B: PowerShell File & Directory Operations (CI Setup)
# --------------------------------------------------------------------------------------------------
# ✅ What It Does:
#    Creates nested folders and moves files directly from PowerShell without using Windows Explorer.
#
# 📅 When to Use:
#    - Creating hidden directories like '.github/workflows'.
#    - Moving terraform workflow YAML files into their required paths.
# ==================================================================================================

# Create the nested directory structure if missing
New-Item -ItemType Directory -Path ".github\workflows" -Force

# Relocate workflow file into GitHub Actions directory
Move-Item -Path "terraform-ci.yml" -Destination ".github\workflows\terraform-ci.yml"

# ==================================================================================================
# 🪣 Section 3: Provisioning Remote State Backend (GCS Bucket)
# --------------------------------------------------------------------------------------------------
# ✅ What It Does:
#    Creates a secure, globally unique GCS bucket to hold 'terraform.tfstate' remote lock files.
#
# 📅 When to Use:
#    - Once per environment/platform setup before migrating away from local state files.
#
# 💡 Why We Do It:
#    - Prevents local state file loss or drift.
#    - Enables concurrent team collaboration and automatic object locking.
# ==================================================================================================

# Create Bucket with uniform access control in EU region
gcloud storage buckets create gs://gcp-terraform-tmp-tfstate-prasanna `
  --project=gcp-terraform-tmp `
  --location=EU `
  --uniform-bucket-level-access

# Enable Object Versioning (Critical for state recovery / audit history)
gcloud storage buckets update gs://gcp-terraform-tmp-tfstate-prasanna --versioning


# ==================================================================================================
# 🔁 Section 4: Migrating Local State to GCS Remote Backend
# --------------------------------------------------------------------------------------------------
# ✅ What It Does:
#    Transfers existing infrastructure tracking (e.g., BigQuery dataset) from local hard drive to GCS.
#
# 📅 When to Use:
#    - Right after adding the 'backend "gcs"' block to domain main.tf.
# ==================================================================================================

# Step 1: Ensure backend block exists in domains/h1_gci_marketing/main.tf:
# terraform {
#   backend "gcs" {
#     bucket = "gcp-terraform-tmp-tfstate-prasanna"
#     prefix = "domains/h1_gci_marketing"
#   }
# }

# Step 2: Run Init from Domain Directory
cd "C:\Users\prasa\Root\Terraform Infrastructure\domains\h1_gci_marketing"
terraform init

# Step 3: When prompted: "Do you want to copy existing state to the new backend?"
# Type: yes


# ==================================================================================================
# 🚀 Section 5: The Standard Local Development Execution Loop
# --------------------------------------------------------------------------------------------------
# ✅ What It Does:
#    Formally formats, initializes, plans, and applies infrastructure changes cleanly.
#
# 📅 When to Use:
#    Whenever you modify or add any .tf file locally.
# ==================================================================================================

# 1. Format Code (Run from project root to format ALL modules and domains)
cd "C:\Users\prasa\Root\Terraform Infrastructure"
terraform fmt -recursive

# 2. Navigate to Domain Directory
cd "C:\Users\prasa\Root\Terraform Infrastructure\domains\h1_gci_marketing"

# 3. Initialize Domain (Downloads modules and provider plugins)
terraform init

# 4. Validate Syntax & Structure
terraform validate

# 5. Preview Changes (Dry-Run)
terraform plan

# 6. Deploy Changes to Google Cloud
terraform apply

# ==================================================================================================
# 🌿 Section 5B: Feature Branching & Pull Request (PR) Workflow
# --------------------------------------------------------------------------------------------------
# ✅ What It Does:
#    Isolates infrastructure changes on a feature branch before merging into 'master'.
#
# 📅 When to Use:
#    - Recommended for team environments where direct pushes to 'master' are restricted.
#    - Testing new modules safely without impacting live state.
# ==================================================================================================

# 1. Create and switch to a new feature branch
git checkout -b feature/add-sales-domain

# 2. Append test comment or make module updates
Add-Content domains/h1_gci_marketing/main.tf "`n# Domain update check"

# 3. Stage, commit, and push upstream
git add .
git commit -m "V1.0.X — Feature / Test Branch Pipeline Execution"
git push -u origin feature/add-sales-domain

# 4. Open Pull Request on GitHub -> Merge to master after CI passes -> Return to local master:
git checkout master
git pull origin master
```

# ==================================================================================================
# 🧹 Section 5C: Sandbox Teardown & Resource Destruction
# --------------------------------------------------------------------------------------------------
# ✅ What It Does:
#    Destroys all GCP resources tracked in the current domain state file.
#
# 📅 When to Use:
#    - Cleaning up temporary sandbox testing resources to prevent unwanted costs.
#
# ⚠️ Warning:
#    This permanently deletes BigQuery datasets, tables, and IAM bindings!
# ==================================================================================================

cd "C:\Users\prasa\Root\Terraform Infrastructure\domains\h1_gci_marketing"

# Preview resources scheduled for destruction
terraform plan -destroy

# Execute resource teardown
terraform destroy

# ==================================================================================================
# ⚙️ Section 6: CI/CD Pipeline Architecture (GitHub Actions)
# --------------------------------------------------------------------------------------------------
# ✅ File Location: .github/workflows/terraform-ci.yml
#
# 🔑 Critical CI Rules Established:
# 1. Directory Strictness: Workflow MUST live inside '.github/workflows/'.
# 2. Branch Matching: Triggers on both 'main' and 'master' branches.
# 3. Path Filtering: Only triggers if files under 'modules/**', 'domains/**', or '.github/workflows/**' change.
# 4. Backend Authentication Bypass: Must use 'terraform init -backend=false' during automated CI check.
#    (Reason: CI runners lack GCP service account keys for state bucket access during syntax validation).
# 5. Action Versions: Uses actions/checkout@v4 and hashicorp/setup-terraform@v3 to avoid Node.js deprecations.
# ==================================================================================================


# ==================================================================================================
# 🧩 Section 7: Troubleshooting & Errors Matrix
# --------------------------------------------------------------------------------------------------
# Error / Symptom                    | Cause                                   | Proven Solution
# -----------------------------------|-----------------------------------------|-------------------------------------------------------
# gcloud.storage: Unauthenticated    | No active GCP account in terminal       | Run 'gcloud auth login'
# CI Exit Code 3                     | Unformatted .tf code pushed to git      | Run 'terraform fmt -recursive' & push fix
# Actions Tab: 0 Workflow Runs       | Workflow file placed in wrong folder    | Move file to '.github/workflows/terraform-ci.yml'
# Actions Tab: 0 Workflow Runs       | Path filtering ignored unchanged files  | Commit a change inside 'domains/' or 'modules/'
# YAML Syntax Error in Workflow      | Incorrect indentation under 'on:'       | Keep 'push:' and 'pull_request:' at same indent level
# CI Failure: Storage Backend Auth   | Runner trying to access GCS without key | Add '-backend=false' to 'terraform init' in YAML
# Node.js 20 Deprecation Warning     | Legacy GitHub Actions versions used     | Upgrade workflow to checkout@v4 & setup-terraform@v3
# ==================================================================================================


# ==================================================================================================
# 🧠 Section 8: The Daily "Muscle Memory" Workflow
# --------------------------------------------------------------------------------------------------
# 1. Open PowerShell Terminal at Root:
#    > cd "C:\Users\prasa\Root\Terraform Infrastructure"
#
# 2. Make code adjustments in PyCharm (modules/ or domains/).
#
# 3. Format all code cleanly:
#    > terraform fmt -recursive
#
# 4. Test locally in domain folder:
#    > cd domains/h1_gci_marketing
#    > terraform validate
#    > terraform plan
#
# 5. Commit using standardized version format:
#    > git add .
#    > git commit -m "V1.0.X — [Domain/Module] / [Task Description]"
#    > git push origin master
#
# 6. Verify automated green checkmark in GitHub Actions tab.
# ==================================================================================================