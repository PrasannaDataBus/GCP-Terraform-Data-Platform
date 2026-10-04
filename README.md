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
* **Dynamic Matrix CI/CD Engine:** GitHub Actions automatically discovers new domain folders at runtime and spins up parallel validation tasks (fmt, init, validate) on every code push or Pull Request—scaling the platform infinitely with zero YAML maintenance.
* **Remote State Locking:** Zero risk of state corruption using Google Cloud Storage (GCS) with object versioning enabled.
* **Automated Scaffolding:** An integrated Cookiecutter templating engine instantly generates standardized Medallion Architecture landing zones, eliminating manual main.tf creation for domains and enforcing consistent module usage across all new domains.
* **Real-Time Streaming & Observability-as-a-Service:** Provisions GCP Pub/Sub topics and subscriptions with automated Dead Letter Queues (DLQ) for fault-tolerant event processing and decoupled Dataflow compute identities.
* **Observability-as-a-Service (BigQuery):** Centralized, $0-cost Log Sinks auto-deployed to every domain, aggressively filtering for query failures (`severity >= ERROR`) to enable proactive incident management without inflating cloud ingestion bills.
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
│       ├── terraform-ci.yml          # CI: Validates formatting and syntax on Pull Requests
│       └── terraform-cd.yml          # CD: Authenticates via ... & runs terraform apply on Master
├── modules/
│   └── data_platform_bigquery/       # Core reusable module for BigQuery datasets & IAM
│       ├── main.tf                   # Defines google_bigquery_dataset & IAM resources
│       ├── variables.tf              # Input variable definitions & validation rules
│       └── outputs.tf                # Module outputs (dataset ID, references, self-link)
│   └── data_platform_streaming/      # Core reusable module for real-time streaming infrastructure
│       ├── main.tf                   # Defines Pub/Sub topics, DLQ, and isolated Dataflow IAM
│       └── variables.tf              # Input variables with GCP regex input sanitization
├── templates/                                # Scaffolding tools for platform automation
│   └── cookiecutter-gcp-domain-template/     # Jinja-templated engine for new data domains
│       ├── cookiecutter.json                 # Variables schema prompted to the engineer
│       └── {{cookiecutter.environment}}/     # Dynamic environment folder[cite: 3]
│           └── h1_{{cookiecutter.domain_slug}}/ # Dynamic domain folder[cite: 3]
│               └── main.tf                   # Templated Medallion dataset orchestrator[cite: 3]
├── domains/
│   ├── dev/                          # Development Environment Domain Orchestrators
│   │   ├── h0_core_iam/              # Core IAM bindings & worker identities (Airflow/dbt)
│   │   │   └── main.tf
│   │   ├── h1_gci_customer/
│   │   │   └── main.tf               # Dev Customer Medallion (Raw & Silver) and Streaming zones
│   │   ├── h1_gci_finance/
│   │   │   └── main.tf               # Dev Customer Medallion (Raw & Silver) and Streaming zones
│   │   ├── h1_gci_inventory/
│   │   │   └── main.tf               # Dev Customer Medallion (Raw & Silver) and Streaming zones
│   │   ├── h1_gci_marketing/
│   │   │   └── main.tf               # Dev Marketing Medallion (Raw & Silver) zones
│   │   └── h1_gci_sales/
│   │       └── main.tf               # Dev Sales Medallion (Raw & Silver) zones
│   │   └── h1_gci_supply_chain/
│   │       └── main.tf               # Dev Supply Chain Medallion (Raw) and Streaming zones
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

resource "google_logging_project_sink" "domain_error_sink" {
  name                   = "${var.dataset_id}-bq-error-sink-${var.environment}"
  destination            = "[logging.googleapis.com/projects/$](https://logging.googleapis.com/projects/$){var.project_id}/locations/global/buckets/_Default"
  filter                 = "resource.type=\"bigquery_resource\" AND severity >= ERROR"
  unique_writer_identity = true
}
```
----

## ⚡ Reusable Streaming Module Engine (`modules/data_platform_streaming`)

This module provisions real-time event streaming infrastructure while enforcing platform guardrails, Observability-as-a-Service, and FinOps labeling.

### Input Variables (`variables.tf`)

* **`project_id`** *(String, Required)*: The target GCP Project ID.
* **`domain_name`** *(String, Required)*: Business domain slug (e.g., `"gci_customer"`).
* **`environment`** *(String, Required)*: Target deployment stage (`"dev"`, `"prod"`).
* **`cost_center`** *(String, Required)*: Mandatory FinOps cost tracking label (e.g., `"customer_engineering"`).
* **`topic_name`** *(String, Required)*: Base identifier for the streaming event topic (e.g., `"operational-events"`).

### Module Logic (`main.tf`)

```hcl
# 1. Dead Letter Queue (DLQ) Topic — Enforces Observability-as-a-Service
resource "google_pubsub_topic" "dlq_topic" {
  name    = "${var.domain_name}-${var.topic_name}-dlq-${var.environment}"
  project = var.project_id

  labels = {
    environment = var.environment
    cost_center = var.cost_center
    domain      = var.domain_name
    type        = "streaming-dlq"
  }
}

# 2. Main Streaming Event Topic
resource "google_pubsub_topic" "main_topic" {
  name    = "${var.domain_name}-${var.topic_name}-${var.environment}"
  project = var.project_id

  labels = {
    environment = var.environment
    cost_center = var.cost_center
    domain      = var.domain_name
    type        = "streaming-main"
  }
}

# 3. Subscription with Automated DLQ Routing
resource "google_pubsub_subscription" "main_subscription" {
  name    = "${var.domain_name}-${var.topic_name}-sub-${var.environment}"
  project = var.project_id
  topic   = google_pubsub_topic.main_topic.name

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq_topic.id
    max_delivery_attempts = 5
  }

  labels = {
    environment = var.environment
    cost_center = var.cost_center
  }
}

# 4. Decoupled Identity for Real-time Compute (Dataflow)
resource "google_service_account" "streaming_worker" {
  account_id   = "sa-${replace(var.domain_name, "_", "-")}-str-${var.environment}"
  display_name = "Dataflow Streaming Worker for ${var.domain_name}"
  project      = var.project_id
}
```

---

## 🌐 Domain Implementation (domains/h1_gci_marketing) | (domains/dev/h1_gci_customer/main.tf)
The domain configuration instantiates the BigQuery module and binds it to remote GCS state management.

Domain Blueprint (domains/h1_gci_marketing/main.tf) | (domains/dev/h1_gci_customer/main.tf) | and other domains

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

# REAL-TIME ZONE - Pub/Sub Streaming & DLQ Infrastructure
module "gci_customer_streaming_zone" {
  source      = "../../../modules/data_platform_streaming"
  project_id  = "gcp-terraform-tmp"
  domain_name = "gci_customer"
  environment = "dev"
  cost_center = "customer_engineering"
  topic_name  = "operational-events"
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

**How to scaffold a new domain (Batch + Real-Time):**
```
# Execute Cookiecutter from root with output directory targeting and merge flags
cookiecutter templates/cookiecutter-gcp-domain-template -o domains/ -f
```
Supported Options:

**Include_realtime_streaming:** When set to yes, automatically injects the data_platform_streaming module into the domain's main.tf, generating Pub/Sub topics, DLQs, and Dataflow service accounts.

---

## ⚙️ CI/CD Pipeline & GitHub Actions Automation (Two-Phase Dynamic Discovery)

To prevent Platform Engineers from becoming a deployment bottleneck, both pipelines utilize a Dynamic Execution Matrix. Instead of hardcoding domain paths, Job 1 automatically scans the repository at runtime to discover all active environments. Job 2 then consumes that JSON array to instantly spin up parallel validation and deployment tasks.

**1. Continuous Integration (CI) — `.github/workflows/terraform-ci.yml`**
Triggers exclusively on **Pull Requests**. It runs `terraform fmt` and `terraform validate` using `-backend=false`. It requires no GCP credentials and acts as a strict syntax gatekeeper before code can merge.

### Pipeline Execution Workflow (Dynamic Discovery)

```yaml
name: Platform Infrastructure CI

on:
  pull_request:
    branches: [ main, master ]
    paths:
      - 'modules/**'
      - 'domains/**'
      - '.github/workflows/**'

jobs:
  setup-matrix:
    name: 'Discover Domain Folders'
    runs-on: ubuntu-latest
    outputs:
      target_dirs: ${{ steps.set-dirs.outputs.matrix }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Scan directories and output JSON
        id: set-dirs
        run: |
          cd domains
          DIRS=$(find . -mindepth 2 -maxdepth 2 -type d | sed 's|^\./||' | jq -R -s -c 'split("\n")[:-1]')
          echo "matrix=$DIRS" >> $GITHUB_OUTPUT

  terraform-validate:
    name: 'Validate (${{ matrix.target_dir }})'
    needs: setup-matrix
    runs-on: ubuntu-latest
    strategy:
      matrix:
        target_dir: ${{ fromJson(needs.setup-matrix.outputs.target_dirs) }}

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.16.2

      - name: Terraform Format Check
        run: |
          terraform fmt -check -recursive modules/
          terraform fmt -check -recursive domains/

      - name: Terraform Init (No Backend)
        run: terraform init -backend=false
        working-directory: ./domains/${{ matrix.target_dir }}

      - name: Terraform Validate
        run: terraform validate
        working-directory: ./domains/${{ matrix.target_dir }}
```

**2. Continuous Deployment (CD) — `.github/workflows/terraform-cd.yml`**

Triggers exclusively on Pushes to Master. It securely authenticates to GCP using a vaulted Service Account JSON key (GCP_SA_KEY), connects to the remote GCS state, and physically provisions the infrastructure via terraform apply -auto-approve.

```yaml
name: Platform Infrastructure CD (Deploy)

on:
  push:
    branches: [ main, master ]
    paths:
      - 'modules/**'
      - 'domains/**'

jobs:
  setup-matrix:
    # (Same Dynamic Discovery Job as CI)
    name: 'Discover Domain Folders'
    runs-on: ubuntu-latest
    # ...

  terraform-apply:
    name: 'Deploy (${{ matrix.target_dir }})'
    needs: setup-matrix
    runs-on: ubuntu-latest
    strategy:
      matrix:
        target_dir: ${{ fromJson(needs.setup-matrix.outputs.target_dirs) }}

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.16.2

      - name: Terraform Init (Connects to GCS State)
        run: terraform init
        working-directory: ./domains/${{ matrix.target_dir }}

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./domains/${{ matrix.target_dir }}
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
"Our CI pipeline runs static code checks (`terraform fmt` and `terraform validate`). Because these steps only inspect code syntax and structural integrity, they do not require access to live cloud state. Running `terraform init -backend=false` allows the pipeline to validate code quickly and securely without needing GCP service account credentials inside the CI runner environment."

How we prevent state file corruption when multiple engineers work on infrastructure?
"We store our state files in a central Google Cloud Storage bucket with uniform access controls and object versioning. Terraform uses GCS native state locking—when an engineer or pipeline executes ```terraform plan``` or ```apply```, a lock file is written to the GCS bucket, preventing concurrent writes and state corruption."

How does Terraform architecture support FinOps and Cost Optimization?
"Our custom BigQuery module mandates FinOps variables like ```cost_center``` and ```data_sensitivity```. If ```is_temp_sandbox``` is set to ```true```, the module dynamically injects a 30-day table expiration policy ```(default_table_expiration_ms)```. This guarantees that temporary analytics datasets clean up after themselves, eliminating unwanted storage costs automatically."

How does the platform achieve "Observability-as-a-Service" without generating massive cloud logging bills?
"By combining GCP Free Tiers with aggressive FinOps filtering. The Terraform blueprint deploys a Google Cloud Logging Sink for every dataset but enforces a strict filter (`resource.type="bigquery_resource" AND severity >= ERROR`). This discards the millions of standard `INFO` logs generated by successful queries—which cost thousands of dollars to store—and exclusively captures actual pipeline failures. This gives the platform team 100% visibility into broken queries for $0."

---

## 🔒 Security, IAM & Compliance

**1. Principle of Least Privilege:**

Infrastructure access is granted via dedicated IAM bindings (`roles/bigquery.dataEditor`) targeted exclusively at workload service accounts (e.g., `airflow-dev-worker`). Furthermore, the GitHub Actions CI/CD runner operates under strict least-privilege; for example, it requires explicit platform-level grants like `roles/logging.configWriter` to provision observability sinks, ensuring the automation pipeline cannot silently overstep its authorization.

**2. Secret Management:**

Hardcoded credentials, JSON keys, and local state files are strictly excluded from git via ```.gitignore```.

**3. State Encryption:**

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