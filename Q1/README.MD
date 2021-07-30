# This document describes the solution for the DevOps Scenario 1.

# Assumptions
This solution assumes that the Azure resources (Web App service and web app api) already exist in the following environments:

- dev:
  - subscritption: dev-sub
  - webapp name: devopstestwebapi-pi-dev

- qa:
  - subscritption: qa-sub
  - webapp name: devopstestwebapi-pi-qa

- prod:
  - subscritption: prod-sub
  - webapp name: devopstestwebapi-pi-prod


Other assumptions include:

- [A .Net Core application](pp\DevOpsTest\DevOpsTest.sln)
- The Web App Service is running linux
- All approvers have the basic license (visual studio profeessional license) which provides access to approve releases and pipelines.

# Solution Summary
## Configuration
If the Azure Devops orginsation does not exist we would create an Azure DevOps Organisation called 'maerskdevopstest' - https://dev.azure.com/maerskdevopstest.

> I have not created the organisation above to avoid clashing with any futre plans to use that name by Maersk so I have used my own organisation called piroinno.

Create a new project called [DevOpsTest](https://dev.azure.com/piroinno/DevOpsTest).

Next, to deploy into Azure, we would have to create service connections (one for the dev, qa and prod subscriptions) in the DevOpsTest project. It is normal practice to also create a new Azure service principals for each of the service connections and use the service princial secret in the service connections in Azure Devops.

> The app service principals will be granted contributor RBAC permissions on each of the Azure subscriptions. Failing to grant this permission will prevent the Azure Devops from deploying into Azure.

## CICD
A [CICD pipeline](azdo\azure-pieplines.yml) with 4 stages (build, dev, qa and prod) will be created with a commit trigger on the master branch of the repository.

The CICD flow is: _build >> dev >> qa >> prod_

On commit the build will be triggered. By default (or specifying the success condition in the dev stage) on test failure i.e. the build fails then the dev stage will not be deployed into. The [build stage](azdo\templates\job-build.yml) contains 5 tasks:

- Use NuGet: set the version of the nuget client
- NuGet restore: restore the artifacts referenced by the projects in the solution
- Build solution: build the solution and produce artifacts
- Test: Run nunit tests
- Publish: Publish the artifact

A project permision group will be created called 'approvers only'. The qa and the prod stages will have approval gates (with the approval from anyone in the 'approvers only' group) created to prevent code automatically deploying into these environments without approval. When using pipelines for deployment, environment approval gates can be used.

The deployment stages consist of 1 deployment task called 'Deploy API' whihc deploys the API into Azure.