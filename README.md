# 🧱 GCP Data Platform Infrastructure — Terraform & GitHub Actions

## Data Platform Automation, Infrastructure as Code (IaC) & CI/CD Engine

This repository contains the enterprise-grade Infrastructure as Code (IaC) foundation for the Google Cloud Platform (GCP) Data Platform. Built with **HashiCorp Terraform** and automated via **GitHub Actions**, this platform provisions, governs, and scales modular data landing zones across multiple business domains with built-in FinOps labeling, strict IAM controls, and remote state isolation.

---

## 📦 Overview & Enterprise Vision

Modern data platforms require consistent, repeatable, and audit-compliant provisioning of cloud resources. Manual console configuration creates "configuration drift," security risks, and untracked costs. 

This repository solves those challenges by implementing a **Domain-Driven Data Platform Architecture**. Each business unit (e.g., Marketing, Sales, Product) receives an isolated landing zone provisioned through standardized, version-controlled Terraform modules.

### Key Capabilities
* **Declarative Infrastructure:** 100% of BigQuery datasets, IAM bindings, and lifecycle rules defined as code.
* **Domain Isolation:** Separate state prefix isolation per domain to minimize blast radius.
* **Strict Environment & Domain Isolation:** Decoupled Dev and Prod directory trees (`domains/dev/*` and `domains/prod/*`) with dedicated GCS state file prefixes.
* **FinOps Governance:** Mandatory resource labeling (`cost_center`, `data_sensitivity`, `is_temp_sandbox`) enforced at the module layer.
* **Matrix-Based CI/CD Engine:** GitHub Actions automatically checks HCL formatting, initializes providers, and validates syntax in parallel on every code push or Pull Request.
* **Remote State Locking:** Zero risk of state corruption using Google Cloud Storage (GCS) with object versioning enabled.
* **Automated Scaffolding:** An integrated Cookiecutter templating engine instantly generates standardized Medallion Architecture landing zones, eliminating manual main.tf creation for domains and enforcing consistent module usage across all new domains.
---

## 🧱 Architecture Pattern & Design Decisions

```text
                     +------------------------------------------+
                     |        GitHub Repository (Master)        |
                     +------------------------------------------+
                                          |
                                 (git push / PR)
                                          v
                     +------------------------------------------+
                     |  GitHub Actions Parallel Matrix Engine   |
                     |  [dev/marketing]   [dev/sales]           |
                     |  [prod/marketing]  [prod/sales]          |
                     |  (fmt check -> init -> validate)         |
                     +------------------------------------------+
                                          |
                                          v
  +-------------------------------------------------------------------------------+
  |                                  Local Workstation                            |
  |   cd domains/dev/h1_gci_marketing (or sales / prod)                           |                      
  |   terraform init -> terraform plan -> terraform apply                         |
  +-------------------------------------------------------------------------------+
                                 |                    |
        (Reads/Writes State)     |                    | (Provisions Resources)
                                 v                    v
+------------------------------------------+   +---------------------------------------------+
|       Google Cloud Storage (GCS)         |   |         Google Cloud Platform               |
|  gs://gcp-terraform-tmp-tfstate-prasanna |   |          Project: gcp-terraform-tmp         |
|  Prefix: domains/dev/h1_gci_marketing    |   |  - Datasets: dev_raw_* & prod_raw_*         |
|  Prefix: domains/prod/h1_gci_sales       |   |  - IAM: airflow-dev-worker & dbt-dev-worker |
|  (Object Versioning Enabled)             |   |  - FinOps: Labels & Governance              |
+------------------------------------------+   +---------------------------------------------+
```

### Key Architectural Decisions

1. **Modular Engine over Monolithic Code:**
   * Infrastructure code is separated into reusable blueprints (`modules/`) and domain orchestrators (`domains/dev/` and `domains/prod/`).
   * A change to the Marketing domain cannot accidentally alter or destroy Sales domain resources.
   * Deploying or breaking changes in `dev` cannot accidentally alter or destroy `prod` resources or state files.

2. **Backend Authentication Bypass in CI (`-backend=false`):**
   * Static CI checks (`terraform fmt` and `terraform validate`) run inside GitHub Actions without needing live GCP credentials.
   * This drastically enhances security by removing the need to expose sensitive service account keys to CI runners during preliminary validation steps.

3. **Remote State Locking via GCS:**
   * Local `terraform.tfstate` files are strictly banned in production to avoid drift and race conditions.
   * GCS natively handles atomic state locking and object versioning, allowing team-wide collaboration safely.

---

## 📁 Directory & File Anatomy
```text
.
├── .github/
│   └── workflows/
│       └── terraform-ci.yml          # GitHub Actions workflow for automated CI/CD validation
├── modules/
│   └── data_platform_bigquery/       # Core reusable module for BigQuery datasets & IAM
│       ├── main.tf                   # Defines google_bigquery_dataset & IAM resources
│       ├── variables.tf              # Input variable definitions & validation rules
│       └── outputs.tf                # Module outputs (dataset ID, references, self-link)
├── templates/                                # Scaffolding tools for platform automation
│   └── cookiecutter-gcp-domain-template/     # Jinja-templated engine for new data domains
│       ├── cookiecutter.json                 # Variables schema prompted to the engineer
│       └── {{cookiecutter.environment}}/     # Dynamic environment folder[cite: 3]
│           └── h1_{{cookiecutter.domain_slug}}/ # Dynamic domain folder[cite: 3]
│               └── main.tf                   # Templated Medallion dataset orchestrator[cite: 3]
├── domains/
│   ├── dev/                          # Development Environment Domain Orchestrators
│   │   ├── h0_core_iam/              # Core IAM bindings & worker identities (Airflow/dbt)
│   │   ├── h1_gci_marketing/
│   │   │   └── main.tf               # Dev Marketing Medallion (Raw & Silver) zones
│   │   └── h1_gci_sales/
│   │       └── main.tf               # Dev Sales Medallion (Raw & Silver) zones
│   └── prod/                         # Production Environment Domain Orchestrators
│       ├── h0_core_iam/              # Core IAM bindings & worker identities (Airflow/dbt)
│       ├── h1_gci_marketing/
│       │   └── main.tf               # Prod Marketing Medallion (Raw & Silver) zones
│       └── h1_gci_sales/
│           └── main.tf               # Prod Sales Medallion (Raw & Silver) zones
├── .gitignore                        # Standard Terraform & local state exclusion rules
├── HANDBOOK.md                       # Comprehensive operational handbook & CLI reference
└── README.md                         # Repository documentation (this file)
```

### Module vs. Domain Breakdown

| Directory Level | Purpose | Example Responsibilities |
| :--- | :--- | :--- |
| **`modules/`** | **Blueprint Layer** | Defines *how* resources are constructed. Enforces mandatory input variables, default labels, and IAM access rules. Contains no hardcoded project IDs or environment names. |
| **`domains/dev/ & domains/prod/`** | **Instantiation Layer** | Defines what is actually deployed per environment. Passes environment parameters (e.g., environment = "dev") into the module and connects to dedicated GCS remote state paths. |

---

## 🔌 Reusable Module Engine (`modules/data_platform_bigquery`)

This module enforces enterprise standards across every BigQuery dataset created on the platform.

### Input Variables (`variables.tf`)

* **`project_id`** *(String, Required)*: The target GCP Project ID (e.g., `gcp-terraform-tmp`).
* **`dataset_id`** *(String, Required)*: Unique identifier for the dataset (e.g., `dev_raw_gci_marketing_prod`).
* **`location`** *(String, Optional)*: BigQuery dataset region. Defaults to `"EU"`.
* **`cost_center`** *(String, Required)*: FinOps cost tracking label (e.g., `"gci_marketing_emea"`).
* **`data_sensitivity`** *(String, Required)*: Data classification tag (`"public"`, `"internal"`, `"pii"`, `"confidential"`).
* **`is_temp_sandbox`** *(Bool, Required)*: Sandbox flag. If `true`, applies an automatic 30-day table expiration policy.
* **`dataset_editors`** *(List of Strings, Optional)*: Service accounts or users granted `roles/bigquery.dataEditor`.
* **`dataset_viewers`** *(List of Strings, Optional)*: Downstream consumers (like dbt) granted `roles/bigquery.dataViewer` for read-only Medallion Architecture access.

### Module Logic (`main.tf`)

```hcl
resource "google_bigquery_dataset" "this" {
  project                    = var.project_id
  dataset_id                 = var.dataset_id
  location                   = var.location
  delete_contents_on_destroy = false

  labels = {
    environment      = var.is_temp_sandbox ? "sandbox" : "production"
    cost_center      = var.cost_center
    data_sensitivity = var.data_sensitivity
    managed_by       = "terraform"
  }

  dynamic "default_table_expiration_ms" {
    for_each = var.is_temp_sandbox ? [2592000000] : [] # 30 Days in ms
    content {
      value = default_table_expiration_ms.value
    }
  }
}

resource "google_bigquery_dataset_iam_binding" "editors" {
  count      = length(var.dataset_editors) > 0 ? 1 : 0
  project    = var.project_id
  dataset_id = google_bigquery_dataset.this.dataset_id
  role       = "roles/bigquery.dataEditor"
  members    = var.dataset_editors
}
```
----

## 🌐 Domain Implementation (domains/h1_gci_marketing)
The domain configuration instantiates the BigQuery module and binds it to remote GCS state management.

Domain Blueprint (domains/h1_gci_marketing/main.tf)

```
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.4.0"
    }
  }

  backend "gcs" {
    bucket = "gcp-terraform-tmp-tfstate-prasanna"
    prefix = "domains/dev/h1_gci_marketing"
  }
}

provider "google" {
  # Connection settings inherited from environment or gcloud context
}

# BRONZE (RAW) ZONE - Airflow Writes, dbt Reads
module "gci_marketing_landing_zone" {
  source           = "../../../modules/data_platform_bigquery"
  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_raw_gci_marketing"
  location         = "EU"
  cost_center      = "gci_marketing_emea"
  data_sensitivity = "pii"
  is_temp_sandbox  = false

  dataset_editors = [
    "serviceAccount:airflow-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
  dataset_viewers = [
    "serviceAccount:dbt-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}

# SILVER ZONE - dbt Transforms & Writes
module "gci_marketing_silver_zone" {
  source           = "../../../modules/data_platform_bigquery"
  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_silver_gci_marketing"
  location         = "EU"
  cost_center      = "gci_marketing_emea"
  data_sensitivity = "pii"
  is_temp_sandbox  = false

  dataset_editors = [
    "serviceAccount:dbt-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}
```
---

## 🪣 Remote State Engine & FinOps Governance

**1. GCS Remote Backend Configuration:** Local state management leads to concurrency issues and data loss. This platform leverages a dedicated GCS storage bucket:

Bucket Name: ``gs://gcp-terraform-tmp-tfstate-prasanna``

Storage Class: Standard (EU Region)

Access Control: Uniform bucket-level access enabled

Recovery Security: Object Versioning enabled for state history rollback.

**2. FinOps Labeling Policy:** To maintain strict cost allocation across business units, every provisioned resource automatically inherits standardized labels:

``managed_by:`` Always set to "terraform" to identify automated vs. manual resources.

``cost_center:`` Tracks specific department budgets (e.g., gci_marketing_emea).

``data_sensitivity:`` Governs compliance and security scanning (pii, internal, confidential).

``environment:`` Automatically set to ``"dev|sandbox"`` or ``"prod|sandbox"`` based on module parameters.

## 🏗️ Automated Domain Scaffolding (Cookiecutter)

To eliminate manual configuration drift when onboarding new business units, this platform utilizes a localized Cookiecutter template to programmatically generate domain landing zones.

**How to scaffold a new domain:**
```
# Navigate to the target environment directory
cd domains

# Run the Cookiecutter generator
cookiecutter ../templates/cookiecutter-gcp-domain-template
```

## ⚙️ CI/CD Pipeline & GitHub Actions Automation

The CI/CD pipeline defined in ``.github/workflows/terraform-ci.yml`` validates every pull request and push to ``main`` or ``master``.

### Pipeline Execution Workflow

```
name: Platform Infrastructure CI

on:
  push:
    branches: [ main, master ]
    paths:
      - 'modules/**'
      - 'domains/**'
      - '.github/workflows/**'
  pull_request:
    branches: [ main, master ]
    paths:
      - 'modules/**'
      - 'domains/**'
      - '.github/workflows/**'

jobs:
  terraform-validate:
    name: 'Validate (${{ matrix.domain }})'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        domain:
          - 'domains/dev/h0_core_iam'
          - 'domains/dev/h1_gci_marketing'
          - 'domains/dev/h1_gci_sales'
          - 'domains/dev/h1_gci_inventory'
          - 'domains/prod/h0_core_iam'
          - 'domains/prod/h1_gci_marketing'
          - 'domains/prod/h1_gci_sales'

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.16.2

      - name: Check Formatting
        run: terraform fmt -check -recursive

      - name: Initialize Domain
        run: terraform init -backend=false
        working-directory: ./${{ matrix.domain }}

      - name: Validate Domain Syntax
        run: terraform validate
        working-directory: ./${{ matrix.domain }}
```
---

## 🚀 Execution Workflow & Daily Operations

**1. Authenticate Terminal with GCP**

```
# Authenticate gcloud CLI
gcloud auth login

# Set sandbox project
gcloud config set project gcp-terraform-tmp
```

**2. Format All HCL Files**

```
# Run from repository root to format modules and domains recursively
cd "C:\Users\prasa\Root\Terraform Infrastructure"
terraform fmt -recursive
```

**3A. Initialize & Deploy Domain - Dev Environment**

```
# Navigate into target domain directory
cd "C:\Users\prasa\Root\Terraform Infrastructure\domains\dev\h1_gci_marketing"

# Initialize remote GCS backend & download providers
terraform init

# Validate configuration syntax
terraform validate

# Execution Dry-Run
terraform plan

# Apply changes to GCP
terraform apply
```

**3B. Initialize & Deploy Domain - Prod Environment**

```
# Navigate into target domain directory
cd "C:\Users\prasa\Root\Terraform Infrastructure\domains\prod\h1_gci_marketing"

# Initialize remote GCS backend & download providers
terraform init

# Validate configuration syntax
terraform validate

# Execution Dry-Run
terraform plan

# Apply changes to GCP
terraform apply
```

**4. Git Versioning & Commit Pattern**

```
git add .
git commit -m "V1.0.4 — Domain State / Migrate H1 GCI Marketing State to GCS Remote Backend"
git push origin master
```

Notes:

Why we separate ``modules/`` and ``domains/`` instead of keeping all code in one folder?
"Separating modules from domains enforces the DRY (Don't Repeat Yourself) principle and controls the blast radius. The module acts as an enterprise template containing security standards, labeling policies, and IAM rules. The domain layer simply consumes the module and passes specific parameters. This guarantees that deploying changes to Marketing will never interfere with Sales state files or resources."

Why we use ```-backend=false``` during ```terraform init``` in your GitHub Actions pipeline?
"Our CI pipeline runs static code checks (```terraform fmt``` and ```terraform validate```). Because these steps only inspect code syntax and structural integrity, they do not require access to live cloud state. Running ```terraform init -backend=false``` allows the pipeline to validate code quickly and securely without needing GCP service account credentials inside the CI runner environment."

How we prevent state file corruption when multiple engineers work on infrastructure?
"We store our state files in a central Google Cloud Storage bucket with uniform access controls and object versioning. Terraform uses GCS native state locking—when an engineer or pipeline executes ```terraform plan``` or ```apply```, a lock file is written to the GCS bucket, preventing concurrent writes and state corruption."

How does Terraform architecture support FinOps and Cost Optimization?
"Our custom BigQuery module mandates FinOps variables like ```cost_center``` and ```data_sensitivity```. If ```is_temp_sandbox``` is set to ```true```, the module dynamically injects a 30-day table expiration policy ```(default_table_expiration_ms)```. This guarantees that temporary analytics datasets clean up after themselves, eliminating unwanted storage costs automatically."

---

## 🔒 Security, IAM & Compliance

**1. Principle of Least Privilege:**

Infrastructure access is granted via dedicated IAM bindings ```(roles/bigquery.dataEditor)``` targeted exclusively at workload service accounts ```(e.g., airflow-dev-worker and dbt-dev-worker)```.

**2. Secret Management:**

Hardcoded credentials, JSON keys, and local state files are strictly excluded from git via ```.gitignore```.

3. State Encryption:

Remote state stored in GCS is encrypted at rest using Google-managed encryption keys (CMEK ready).

---

## 🧱 Commit & Versioning Strategy

This project strictly follows semantic commit versioning to maintain a clear audit trail:

```V[x.x.x] — [Category / Component] / [Action Taken]```

Examples:

```V1.0.0 — Project Initialization / Standardize Repo Structure and Ignored Files```

```V1.0.2 — HCL Formatting / Enforce Canonical Style Rules```

```V1.0.4 — Domain State / Migrate H1 GCI Marketing State to GCS Remote Backend```

```V1.0.5 — CI Engine / Disable Backend Auth for CI Validation Step```

---

## 🧠 Author & Maintainer

Prasanna — Senior Data Engineer

Email: prasannadatabuss@gmail.com

GitHub: PrasannaDataBus

Repository: GCP-Terraform-Data-Platform

🏁 License
This repository and its contents are proprietary to PrasannaDataBus. Unauthorized redistribution, public sharing of API credentials, or unapproved deployment of this architecture is strictly prohibited.