# Setup Azure DevOps project

When Azure resource group and environment is setup, next step is to configure all Azure DevOps project requirements for build and release pipelines. This includes repository, service endpoints, build variables.

## 1. Publish build scripts

This task publishes scripts from this repository, so they are available for other Azure Pipelines.

1. Fork this repository in GitHub.
2. Open Azure DevOps project, where you want to setup pipeline. Or create a new one.
3. Open **Project Settings**.
4. Open **Service Connections**.
5. Click **New service connection** and select **GitHub**.

![New service connection](images/Setup_Azure_DevOps_project_New_service_connection.png)

6. Enter connection name and click **Authorize**. Optionally you can uncheck **Allow all pipelines to use this connection.** as this is not needed in our scenario.

![GitHub service connection](images/Setup_Azure_DevOps_project_GitHub_service_connection.png)

7. Click **OK**.
8. From menu select **Pipelines** then **Builds**.
9. Create **New build pipeline**.
10. Click **Use the visual designer**.

![New build pipeline](images/Setup_Azure_DevOps_project_New_build_pipeline.png)

11. Select **GitHub** as source and select your forked repository.

![Select repository](images/Setup_Azure_DevOps_project_Select_repository.png)

12. Click **Continue**.
13. Select **YAML** and click **Apply**.
14. Enter following values
    - **Name**: _Build scripts_
    - **Agent pool**: Hosted Windows Container
    - **YAML file path**: azure-pipelines.yml

![Build scripts](images/Setup_Azure_DevOps_project_Build_scripts.png)

15. Click **Save & queue** and queue new build.

## 2. Create connection to Azure Subscription

1. Open **Project Settings**.
2. Open **Service Connections**.
3. Click **New service connection** and select **Azure Resource Manager**.

![New Azure Resource Manager service connection](images/Setup_Azure_DevOps_project_New_Azure_service_connection.png)

4. You can uncheck **Allow all pipelines to use this connection** as this is not needed in our scenario.
5. Select **Service Principal Authentication**.
6. Click **use the full version of the service connection dialog**. Dialog with all options is displayed.
7. Enter following values:
    - **Connection name**: Azure Build
    - **Environment**: AzureCloud
    - **Scope level**: Subscription
    - **Subscription ID**: Subscription ID of your Azure subscription.
    - **Subscription name**: Name of your Azure subscription.
    - **Service principal client ID**: $spClientId returned by _SetupPacker.ps1_ script.
    - **Service principal key**: $spClientSecret returned by _SetupPacker.ps1_ script.
    - **Tenant ID**: $tenantId returned by _SetupPacker.ps1_ script.

![Azure Resource Manager service connection](images/Setup_Azure_DevOps_project_Azure_service_connection.png)

8. Click **Verify connection** and then click **OK**.

## 3. Setup build variables

1. From menu select **Pipelines** then **Library**.
2. Open **Variable groups**.
3. Create new variable group named **Azure subscription** with following values:

| Name                 | Value                                                 | Hidden |
|----------------------|-------------------------------------------------------|--------|
| Azure.ClientId       | $spClientId returned by _SetupPacker.ps1_ script.     |        |
| Azure.ClientSecret   | $spClientSecret returned by _SetupPacker.ps1_ script. | true   |
| Azure.SubscriptionId | Subscription ID of your Azure subscription.           |        |
| Azure.TenantId       | $tenantId returned by _SetupPacker.ps1_ script.       | true   |

4. You can uncheck **Allow access to all pipelines** as this is not needed in our scenario.

![Variable group - Azure subscription](images/Setup_Azure_DevOps_project_Variable_group_Azure_subscription.png)

5. Click **Save**.
6. Create new variable group named **Azure resources** with following values:

| Name                     | Value                                                     |
|--------------------------|-----------------------------------------------------------|
| Azure.Location           | $location returned by _SetupPacker.ps1_ script.           |
| Azure.ResourceGroup      | $rgName returned by _SetupPacker.ps1_ script.             |
| Azure.StorageAccountName | $storageAccountName returned by _SetupPacker.ps1_ script. |

7. You can uncheck **Allow access to all pipelines** as this is not needed in our scenario.

![Variable group - Azure resources](images/Setup_Azure_DevOps_project_Variable_group_Azure_resources.png)

8. Click **Save**.
9. Click user icon in upper right corner and select **Security**.
10. Select **Personal access tokens**.
11. Click **New Token**.
12. Set **Name** to "BuildAgent".
13. Set **Expiration** to 90 days.
14. Click **Show all scopes**.
15. Check **Agent Pools - Read & manage**.

![Create Personal Access Token](images/Setup_Azure_DevOps_project_Personal_Access_Token.png)

16. Click **Create**.
17. Save created token for later use.
18. From menu select **Pipelines** then **Library**.
19. Open **Variable groups**.
20. Create new variable group named **Azure DevOps Account** with following values:

| Name                | Value                                      | Hidden |
|---------------------|--------------------------------------------|--------|
| ADOAccount.PAT      | Personal Access Token obtained in step 17. | true   |

21. You can uncheck **Allow access to all pipelines** as this is not needed in our scenario.

![Variable group - Azure DevOps account](images/Setup_Azure_DevOps_project_Variable_group_Azure_DevOps_account.png)

22. Click **Save**.
23. Create new variable group named **Build Agent properties** with following values:

| Name                | Value                                          | Hidden |
|---------------------|------------------------------------------------|--------|
| BuildAgent.Password | Password of admin user created on build agent. | true   |
| BuildAgent.Username | Username of admin user created on build agent. |        |

> Note: Please, follow [requirements for username and password](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq#what-are-the-username-requirements-when-creating-a-vm).

24. You can uncheck **Allow access to all pipelines** as this is not needed in our scenario.

![Variable group - Build Agent properties](images/Setup_Azure_DevOps_project_Variable_group_Build_agent.png)

25. Click **Save**.

Next step: [Create build agent image](Create_build_agent_image.md)
