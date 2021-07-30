# This document describes the solution for the DevOps Scenario 2.

## _1) What are different artifacts you need to create - name of the artifacts and its purpose_

- main.tf: the entry point used by the terraform client (terraform init, plan and apply). All the required terraform resources are defiend in this file.
- outputs.tf: output variables or data to standard out are defined in this file
- variables.tf: variable definations are defined in this file.

## _2) List the tools you will to create and store the Terraform templates._
My personal preference, I use
- VSCode to create the templates
- Git repository to store the templates
  -  Hashicorp terrafrom extention for formarting and linting

## _3) Explain the process and steps to create automated deployment pipeline._

An automated deploymented pipeline allows us to identify bugs and fix them quickly. Hence reducing backlog tasks, toil, improves security and reduces state drift.

### Our automated IaC pipeline should achieve the following objectives:

- Code stored in a version controlled system will be tested when changes are detected
- Deployment to production will need to be approved
- Only the master branch can be deployed into production
- Merges to the master branch will need to be peer reviewed using a PR
- Will not store any sensitive information in the version control system
- Run security tests against targets after changes are applied
- Any stateful information should be stored in a secure versioned location

### We can achieve these objetives by using:

- Azure DevOps pipelines as the ochestration tool triggered on changes in the repository (commits or merges).
- Use an azure storage account (with versioning enabled) to store our terraform state
- Key Vaults to store keys and secrets with RBAC roles and access policies applied. Secret values can be substituted at deploy or build time in the pipeline.
- Use policies to protect the master branch
- Use Azure DevOps tasks such as:
  - Linting and formating tasks to ensure correct formating and code consistency
  - OWASP to check for security vulnerabilities
  - WhiteSource to check to any open source license issues
  - Terratest or powershell pester tests to validate our changes before merging to master or deploying to production

### Steps

- Create an Azure Devops organisation
- Create a project
- Create or use the default project repository
- Apply branch policies to:
  - prevent commits to master
  - allow only approved PRs to merge into master
- Enable continous integration by using triggers in the pipelines
- Create service connections from Azure DevOps into Azure using service principals. The Service principals should be granted contributor on the target subscriptions and also granted permission to read and write in Azure AD.
- Using yml, define the the triggers and stages.
  -  The build stage will pull the source code where it is tested then subsequently packaged into an artifact. Failures can be reported into a slack or teams channel using hooks or connectors
  - the release stages, starting with dev will always be deployed into after a successfull build. Here the chnages are further tested by automatically provisioning a test resource (such as a conatiner for web apps or virtual machine). Once the test has completed the resource is detroyed to reduce costs. Deployment into the qa and production branches can be gated using approval gates and checks to prevent non approved changes from making it into production.


## _4) Create a sample Terraform template you will use to deploy Below services:_
## - _Vnet_
## - _2 Subnet_
## - _NSG to open port 80 and 443_
## - _1 Window VM in each subnet_
## - _1 Storage account_

Created a [default sample template](default_tf_approach\main.tf) where all the resources have been created in the same file. While this pattern works for small environments it does not scale up easily as the number of resources grow. I would recommend using modules and then driving provisioning process using json input variables. 

Another issue with the default template approach is that updates to the priovider modules and even the terraform client can cause errors to occur and render the entire deployment unusable. Modules overcome this issue using versioning. Each module can be stored in its own repository or branch and then sourced and managed independently of the other resources.

example:

In the main.tf file the key vault module can be sourced.

``` 
module "key_vault" {
  source         = "git@ssh.dev.azure.com:v3/piroinno/DevOptsTest/iac?ref=feature/pi/demo"
  ResourceGroups = var.KeyVaults
}
```

Then a new input .tfvars file with the driving parameters can be passed in directly into the module or stored automatically by terraform.

``` json
{
  "KeyVaults": [
    {
      "name": "q2-kv",
      "resourceGroupName": "q2-rg",
      "location": "north europe",
      "SecretAccessPolicies":[
        {
          "objectId": "",
          "permissions": "Get,Set,List,Delete"
        }
      ]
    }
  ]
}
```

## _5) Explain how will you access the password stored in Key Vault and use it as Admin Password in the VM Terraform template._

A random string resource has been used to generate a random string (12 characters, contains upper and lower case with special characters). The random string was used as input into the the virtual machine admin password field. A new key vault resource was added to the template and used to store the admin password as a secret.

## Summary

The entire environment has been [dumped into a dot diagram](default_tf_approach\q1-env.html)