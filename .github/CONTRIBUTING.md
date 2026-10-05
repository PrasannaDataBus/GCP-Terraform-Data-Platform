# Goal

This file acts as the onboarding manual for the platform. When a new data engineer joins the company, this document teaches them how to interact with our architecture.

# Contributing to the Enterprise Data Platform

Welcome to the central infrastructure repository. We operate on a **Data Mesh** model utilizing **InnerSource** community standards. 

## 🤝 How We Collaborate
1. **Domain Autonomy:** Domain teams (e.g., Sales, Marketing) are responsible for managing their own infrastructure configurations within `domains/`.
2. **Platform Guardrails:** The central platform team maintains the reusable Terraform blueprints in `modules/`. 
3. **Never Push to Master:** All changes must be submitted via a Pull Request and pass the automated CI validation matrix.

## 🚀 How to Provision a New Domain
Do not copy/paste existing folders. Use our automated community scaffolding tool:
```bash
cookiecutter templates/cookiecutter-gcp-domain-template
```