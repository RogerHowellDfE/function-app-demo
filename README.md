# Demo of deploying function app

1. Create/identify the Azure resource group
2. Create user-managed system identities - these can persist
   - These identities will appear on Azure Portal as resources within the resource group
   - Create federated credential, linking that identity to the GitHub repository
     - `Organisation`: GitHub repository "owner" (i.e., individual username, or GitHub organisation)
     - `Repository`: GitHub repository "name" (i.e., the repo name)
     - `Entity`: `Environment`
       - (if scoping permissions to a GitHub "environment" - alternatively, can also be a specific branch/tag or generic "pull request")
     - `Environment`: `Development` / `Test` / `Production` (/anything which matches an "Environment" as defined on the GitHub repository)
   - Note: GitHub will create a cryptographically signed (public/private key crypto) request, validating that it is originating from GitHub in one of the above circumstances
     - ... this is, therefore, negating the need for any manual transferring (and management/rotating) of keys or secrets
   - ![image](https://github.com/user-attachments/assets/0b5346be-1cd4-45d5-87aa-64b4761f5741)
3. Create the function app
   - Note: needs to be a premium SKU to allow deployment from a container registry
     - ... therefore _caution_ if creating this on a personal subscription (>£100 / month in costs(!))
   - Cheaper/development tiers allow only direct upload/deployment of function apps, and continuous deployment directly from a GitHub repository
4. Configure / link identity to the function app
   - On the function app, under "Access control (IAM)", add the role of "Website Contributor"
     - ![image](https://github.com/user-attachments/assets/46dad276-b204-4548-82eb-26f8be29fd9b)
     - ![image](https://github.com/user-attachments/assets/a30b58ca-12f3-4c82-aa47-34a9b7eaf756)
     - ![image](https://github.com/user-attachments/assets/648c5ce7-ddab-488e-ab57-81f0f7b67e91)
5. Note relevant Azure identifiers, and add them as environment "secrets"
   - Note they are not _strictly_ secrets due to the PKI crypto as described above (would need to steal/forge details to appear to Azure as if originating from GitHub)
   - `AZURE_CLIENT_ID`: Specific to the user managed system identity
   - `AZURE_TENANT_ID`: Specific to the Azure AD/Entra tenant
   - `AZURE_SUBSCRIPTION_ID`: Specific to the subscription in which the function app/identity exist
7. Run the GitHub Action/Workflow
   - See this pipeline run for examples: https://github.com/RogerHowellDfE/function-app-demo/actions/runs/14022752616
   - If ODIC details above not supplied:
     - > ```
       > Run azure/login@v2
       > Error: Login failed with Error: Using auth-type: SERVICE_PRINCIPAL. Not all values are present. Ensure 'client-id' and 'tenant-id' are supplied.. Double check if the 'auth-type' is correct. Refer to https://github.com/Azure/login#readme for more information.
       > ```
     - ![image](https://github.com/user-attachments/assets/2c3c1385-1045-43f4-b5b5-e944cf547e17)
   - If valid OIDC details supplied, but the managed identity has not been given "Website Contributor" role to a function app:
     - > ```
       > Run azure/login@v2
       >   with:
       >     client-id: ***
       >     tenant-id: ***
       >     subscription-id: ***
       >     enable-AzPSSession: false
       >     environment: azurecloud
       >     allow-no-subscriptions: false
       >     audience: api://AzureADTokenExchange
       >     auth-type: SERVICE_PRINCIPAL
       >   env:
       >     REGISTRY: ghcr.io
       >     IMAGE_NAME: function-app-demo
       > Running Azure CLI Login.
       > /usr/bin/az cloud set -n azurecloud
       > Done setting cloud: "azurecloud"
       > Federated token details:
       >  issuer - https://token.actions.githubusercontent.com
       >  subject claim - repo:RogerHowellDfE/function-app-demo:environment:Development
       > Attempting Azure CLI login by using OIDC...
       > Error: No subscriptions found for ***.
       >
       > Error: Login failed with Error: The process '/usr/bin/az' failed with exit code 1. Double check if the 'auth-type' is correct. Refer to https://github.com/Azure/login#readme for more information.
       > ```
     - ![image](https://github.com/user-attachments/assets/c95332b8-6fc9-49ea-ad45-f27884afd856)
   - If valid OIDC details but invalid SKU for FA (needs premium SKU for linking to container registry) - login will succeed, but deploy will fail
     - > ```
       > Run azure/login@v2
       > Running Azure CLI Login.
       > /usr/bin/az cloud set -n azurecloud
       > Done setting cloud: "azurecloud"
       > Federated token details:
       >  issuer - https://token.actions.githubusercontent.com
       >  subject claim - repo:RogerHowellDfE/function-app-demo:environment:Development
       > Attempting Azure CLI login by using OIDC...
       > Subscription is set successfully.
       > Azure CLI login succeeds by using OIDC.
       > ```
     - > ```
       > Run azure/webapps-deploy@v2
       > Updating App Service Configuration settings. Data: {"linuxFxVersion":"DOCKER|ghcr.io/RogerHowellDfE/function-app-demo/function-app-demo:261d2ca4cc5357d943e04c00045852e9e96f7356"}
       > Error: Deployment Failed, Error: Failed to patch configuration settings for app service fa-docker-demo-dev.
       > BadRequest - The following site configuration property (Site.SiteConfig.LinuxFxVersion) for Flex Consumption sites is invalid.  Please remove or rename it before retrying. (CODE: 400)
       > Warning: Error: Failed to update deployment history.
       > Method Not Allowed (CODE: 405)
       > App Service Application URL: https://fa-docker-demo-dev.azurewebsites.net
       > ```
     - ![image](https://github.com/user-attachments/assets/27295040-e64a-4e01-aeac-67dd6588bc14)

   - If valid OIDC details, roles are assigned, and valid (premium) SKU:
     - > ```
       > Run azure/login@v2
       > Running Azure CLI Login.
       > /usr/bin/az cloud set -n azurecloud
       > Done setting cloud: "azurecloud"
       > Federated token details:
       >  issuer - https://token.actions.githubusercontent.com
       >  subject claim - repo:RogerHowellDfE/function-app-demo:environment:Development
       > Attempting Azure CLI login by using OIDC...
       > Subscription is set successfully.
       > Azure CLI login succeeds by using OIDC.
       > ```
     - > ```
       > Run azure/webapps-deploy@v2
       > Updating App Service Configuration settings. Data: {"linuxFxVersion":"DOCKER|ghcr.io/RogerHowellDfE/function-app-demo/function-app-demo:261d2ca4cc5357d943e04c00045852e9e96f7356"}
       > Updated App Service Configuration settings.
       > Restarting app service: fa-docker-demo-dev
       > Deployment passed
       > Restarted app service: fa-docker-demo-dev
       > Successfully updated deployment History at https://fa-docker-demo-dev.scm.azurewebsites.net/api/deployments/261d2ca4cc5357d943e04c00045852e9e96f73561742763994788
       > App Service Application URL: https://fa-docker-demo-dev.azurewebsites.net
       > ```
     - ![image](https://github.com/user-attachments/assets/18e852f3-bae4-484a-bbca-9c5919640631)
8. Where deployment to a given environment has protection rules (e.g., required approvals), these will appear as execution of the action progresses
   - ![image](https://github.com/user-attachments/assets/685b196e-9fa6-4a08-a8a6-67c093275d7a)
   - ![image](https://github.com/user-attachments/assets/6fdee3ad-65ee-4401-85f0-8c939f7cfc45)
   - ![image](https://github.com/user-attachments/assets/a94134bd-c225-4670-8b12-89b1a77c60eb)
   - ![image](https://github.com/user-attachments/assets/a772432d-acae-4da1-9db6-a3c7ac9efd74)
9. Optionally, review changes made to the function app via Azure Portal
   - Function app deployment configuration
     - ![image](https://github.com/user-attachments/assets/dfc80bd7-a000-487a-94ee-b5aa992d7d0f)


