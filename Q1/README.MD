This document describes the solution for the DevOps Scenario 1.


# Solution Summary
Delivered an integrated CICD pipeline which deploys into a dev environment automatically on a commit to master. Deployment into qa and prod are controlled by approval gates.
- A working pipeline hosted in my public Azure DevOps project: https://dev.azure.com/piroinno/DevOpsTest/_build?definitionId=3&_a=summary
- deployed endpoints:
  - dev:
    - web app: https://devopstestwebapp-pi-dev.azurewebsites.net/
    - web api: https://devopstestwebapi-pi-dev.azurewebsites.net/
  - qa:
    - web app: https://devopstestwebapp-pi-qa.azurewebsites.net/
    - web api: https://devopstestwebapi-pi-qa.azurewebsites.net/
  - prod:
    - web app: https://devopstestwebapp-pi-prod.azurewebsites.net/
    - web api: https://devopstestwebapi-pi-prod.azurewebsites.net/

> To get this working and to ensure my solution is compliant with the scenarios I have cloned my solution from my GitHub repo into an Azure DevOps repo.

> Also worth mentioning is that I have used Azure DevOps [YAML pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/what-is-azure-pipelines?view=azure-devops) simply to reinforce the infrastrucutre as code concept. The deployment pipleine is version controlled.
# Solution Overview

This solution uses Azure resources (resource groups, app service and app api). I have also created a new Azure account (using the free $200 credit for one month).
The following resoruces have been created to fulfill the needs of the dev, qa and prod environments:

- dev:
  - subscritption: dev-sub
  - resource group: q1-rg
  - app service plan: q1-app-plan
  - app service: devopstestwebapp-pi-dev
  - app service: devopstestwebapi-pi-dev

- qa:
  - subscritption: prod-sub
  - resource group: q1-rg
  - app service plan: q1-app-plan
  - app service: devopstestwebapp-pi-qa
  - app service: devopstestwebapi-pi-qa

- prod:
  - subscritption: prod-sub
  - resource group: q1-rg
  - app service plan: q1-app-plan
  - app service: devopstestwebapp-pi-prod
  - app service: devopstestwebapi-pi-prod


## Other important aspects:

- I'm used [.Net Core projects](app/DevOpsTest/DevOpsTest.sln) so I could run the app and api on Linux.
- The Azure app services are running linux
- All pipeline approvers have the basic license (visual studio profeessional license) which provides access to approve releases and pipelines.


## Configuration
Used my existing DevOps organisation called piroinno.

Created a new project called [DevOpsTest](https://dev.azure.com/piroinno/DevOpsTest).

Next, to deploy into Azure, service connections (one for the dev, qa and prod subscriptions) in the DevOpsTest project were created. Authentication was archieved using the best practice - Azure service principals for each of the service connections and use the service princial secret in the service connections in Azure Devops.

> The app service principals were granted contributor RBAC permissions on each of the Azure subscriptions. Failing to grant this permission will prevent the Azure Devops from deploying into Azure.

## CICD
A [CICD pipeline](azdo/azure-pieplines.yml) with 4 stages (build, dev, qa and prod) will be created with a commit trigger on the master branch of the repository.

The CICD flow is: 
>_build (test: unit, code flaws etc) >> dev (scan deployed web app) >> qa (scan deployed web app) >> prod (scan deployed web app)_

### Build
On commit, the build will be triggered. By default (or specifying the success condition in the dev stage) on test failure i.e. the build fails then the dev stage will not be deployed into.

The [build stage](azdo/templates/job-build.yml) contains 8 tasks encapsulated in a job template to meet the following objectives:

- Set the version of the nuget client
- NuGet estore the artifacts referenced by the projects in the solution
- Build the solution and produce artifacts
- Run nunit tests
- Check for any license or open source vulnerabilities
- Archive the built files
- Publish the artifact

### Deployment
Each deployment stage consist of 2 deployment jobs encapsulated in a job template to meet the following objectives:

- Deploy the artifacts
- Checks for known API vulnerabilites.

### QA and Prod
A project permision group 'approvers only' was created to gate the qa and prod stages. Anyone with in the group can approve deployments into qa and prod. This prevents code automatically deploying into these environments without approval.