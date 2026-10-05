## Goal: 

A standardized template forces every community member to pause and verify their code against Kering's FinOps and Security guardrails before triggering our CI matrix.

## 🧱 Infrastructure Modification Request

**Business Context & Justification:**
<!-- Briefly explain why this infrastructure change is required by your domain. -->

### ✅ Community Standards Checklist
- [ ] **Formatting:** I have run `terraform fmt -recursive` locally when all modules need to be rechecked
- [ ] **Formatting:** I have run `terraform fmt -recursive domains/` locally when only domain modules need to be rechecked
- [ ] **Formatting:** I have run `terraform fmt -recursive domains/dev/h1_gci_hr/` locally when particular domain modules need to be rechecked
- [ ] **FinOps:** I have verified the correct `cost_center` label is applied.
- [ ] **Lifecycle:** If this is a temporary environment, `is_temp_sandbox` is set to `true`.
- [ ] **Security:** I am only granting Least Privilege access (`dataViewer` or `dataEditor`) to workload service accounts, not individual users.

### 📊 Cost Impact

<!-- Estimate the GCP cost impact of this change (e.g., "$0 - Free Tier Log Sink", or "+$50/mo for increased storage").-- >