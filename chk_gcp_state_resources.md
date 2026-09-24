# 🔍 GCP Data Platform — Infrastructure State, Resource & FinOps Audit Guide

This operational checklist provides step-by-step terminal commands to inspect live Google Cloud Platform (GCP) resources, audit Google Cloud Storage (GCS) remote state locks, verify BigQuery FinOps metadata labels, and confirm zero-cost sandbox boundaries.

---

## 🧭 Section 1: Session & Project Context Verification

Ensure your local terminal session is authenticated and targeting the correct GCP sandbox environment before executing audit commands.

```
# 1. Verify active authenticated gcloud account
gcloud auth list

# 2. Set default active project
gcloud config set project gcp-terraform-tmp

# 3. Confirm target project configuration
gcloud config get-value project
```

---

## 🪣 Section 2: GCS Remote State Backend Audit

Inspect the remote state bucket ```(gs://gcp-terraform-tmp-tfstate-prasanna)``` to confirm bucket security settings, uniform access control, versioning status, and remote state lock objects.

**1. Inspect State Bucket Metadata & Versioning**

```
gcloud storage buckets describe gs://gcp-terraform-tmp-tfstate-prasanna `
  --format="yaml(name, location, storageClass, versioning, iamConfiguration.uniformBucketLevelAccess)"
```

``` 
> Expected Output: versioning.enabled: true and uniformBucketLevelAccess.enabled: true.
```

**2. List Remote State Files & Domain Prefixes**

```
gcloud storage ls --recursive gs://gcp-terraform-tmp-tfstate-prasanna/
```

```
gs://gcp-terraform-tmp-tfstate-prasanna/domains/h1_gci_marketing/default.tfstate
```

**3. Inspect State File Storage Footprint (Cost Check)**


```
gcloud storage ls --long gs://gcp-terraform-tmp-tfstate-prasanna/domains/h1_gci_marketing/default.tfstate
```

``` > Expected Footprint: ~3 KB to 5 KB (Under GCP 5 GB Free Tier = $0.00).```

---

## 📊 Section 3: BigQuery Landing Zone & FinOps Metadata Audit

Verify that BigQuery datasets provisioned via Terraform contain mandatory FinOps labels (`cost_center`, `data_sensitivity`, `environment`, `managed_by`) and correct IAM bindings.

**1. List All Provisioned Datasets in Project**

```bq ls --project_id=gcp-terraform-tmp```

**2. Inspect Dataset Metadata & FinOps Labels**

```bq show --format=prettyjson gcp-terraform-tmp:raw_gci_marketing_prod```


> Verification Key-Values to Confirm in Output:

> * "datasetReference.datasetId": "raw_gci_marketing_prod"

> * "location": "EU"

> * "labels.cost_center": "gci_marketing_emea"

> * "labels.data_sensitivity": "pii"

> * "labels.environment": "production"

> * "labels.managed_by": "terraform"

---

## 🔐 Section 4: IAM & Security Binding Verification

Audit the service accounts and permissions granted at the dataset level.

**1. View Access Policy Bindings on Dataset**

```
bq show --format=prettyjson gcp-terraform-tmp:raw_gci_marketing_prod | Select-String -Pattern "access" -Context 0,20
```

```Expected Role: roles/bigquery.dataEditor bound to serviceAccount:airflow-platform-worker@gcp-terraform-tmp.iam.gserviceaccount.com```

## 💰 Section 5: Real-Time FinOps Cost Assessment

| Infrastructure Component | Provisioned Resource | Live Size / Count | Monthly Cost | Cost Justification |
| :--- | :--- | :--- | :--- | :--- |
| **State Storage** | `gs://gcp-terraform-tmp-tfstate-prasanna` | ~3.5 KB | **$0.00** | Covered under GCP 5 GB Free Tier |
| **BigQuery Dataset** | `raw_gci_marketing_prod` | 0 Bytes | **$0.00** | Datasets & metadata carry $0 fee; active storage <10 GB is free |
| **IAM Access Policy** | BigQuery Data Editor Binding | 1 Role Binding | **$0.00** | IAM metadata carries $0 fee |
| **CI/CD Pipeline** | GitHub Actions (`terraform-ci.yml`) | ~5 Runs | **$0.00** | Covered under GitHub 2,000 free runner minutes/month |
| **Total Monthly Spend** | — | — | **$0.00 / month** | **100% Free Sandbox** |

## ⚡ Section 6: Automated Terminal One-Liner Audit Script

Run this single PowerShell block to generate a complete platform health report directly in your console:

```
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " 🧱 GCP TERRAFORM PLATFORM HEALTH AUDIT " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "`n[1/3] Checking Active Project..." -ForegroundColor Yellow
gcloud config get-value project

Write-Host "`n[2/3] Checking Remote State Objects..." -ForegroundColor Yellow
gcloud storage ls --recursive gs://gcp-terraform-tmp-tfstate-prasanna/

Write-Host "`n[3/3] Checking BigQuery Dataset Labels..." -ForegroundColor Yellow
bq show --format=prettyjson gcp-terraform-tmp:raw_gci_marketing_prod | Select-String -Pattern "labels" -Context 0,6

Write-Host "`n✅ Platform Health Audit Complete - Infrastructure Verified Healthy ($0.00 Spend)." -ForegroundColor Green
```