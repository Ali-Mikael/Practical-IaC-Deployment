# Practical-IaC-Deployment

This repo is for the "Public Cloud Solution Architect" course, practical IaC deployment. 
It consists of 10 task, which all put together will create you a GitLab-type CI/CD platform in the cloud using terraform and AWS. <br>

<https://pekkakorpi-tassi.fi/courses/pkt-arc/pkt-arc-edu-olt-2025-1e/iac_deployment.html>
<br>

Terraform template can be run when Terraform is installed and provider configured. <br>
For this deployment, I chose to store AWS credentials in `~/.aws/credentials`. This is the place where AWS will look when authorizing/authenticating requests from terraform. <br>
When your credentials are in check, run the configurations with `$ terraform apply`.
