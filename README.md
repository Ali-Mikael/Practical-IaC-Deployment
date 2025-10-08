# Practical-IaC-Deployment

This repo is for the "Public Cloud Solution Architect" course, practical IaC deployment. 
It consists of 10 tasks, which all put together will create for you a **functional CI/CD platform similar to GitLab**, hosted in the cloud, using Terraform and AWS. <br>

<https://pekkakorpi-tassi.fi/courses/pkt-arc/pkt-arc-edu-olt-2025-1e/iac_deployment.html>
<br>

Terraform template can be run when Terraform is installed and provider configured. <br>
For this deployment, I chose to store AWS credentials in `~/.aws/credentials`. This is the place where AWS will look when authorizing/authenticating requests from terraform. <br>
When your credentials are in check initialize terraform with `$ terraform init`, run the configurations with `$ terraform apply`.
