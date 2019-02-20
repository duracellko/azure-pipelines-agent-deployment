# Setup Azure Resource Group

First step is to setup environment for the build agent. Microsoft Azure is used for 2 things:

1. Virtual Machine running Azure DevOps build agent
2. Azure Storage to store disk images of the Virtual Machine

Both will be in single Azure Resource Group. Additionally it is needed to setup [Azure Active Directory Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals) that will authorize Azure DevOps to access the Azure Resource Group.

[SetupPacker.ps1](../scripts/SetupPacker.ps1) script in this repository will help you setup Azure Resource Group. It has following arguments:

- **subscriptionId** - ID of your Azure Subscription. You can find it in Azure Portal.
- **rgName** - Name of Azure Resource Group you want to create.
- **location** - Location of Azure data center that the build agent should run in. This should be same as location of your Azure DevOps organization.
- **storageAccountName** - name of Azure Storage account that will store images of virtual machines. Name must follow restrictions for [Azure Storage account name](https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions#naming-rules-and-restrictions) (length 3 - 24, all lowercase, alphanumeric only, no special characters).
- **spDisplayName** - Display name of Azure Active Directory Service Principal that will be created to access the Azure Resource Group.
- **spClientSecret** - Password of the Azure Active Directory Service Principal. This value must be kept secret.

The script uses [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/overview?view=azps-1.2.0). Follow [installation instructions](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-1.2.0) for Azure PowerShell. When Azure PowerShell is installed, then you can run the script like this:

```PowerShell
# Login to Azure subscription interactively
Connect-AzAccount

$subscriptionId = "900ff9b6-46df-40aa-b322-d651cd3399cd"
$rgName = "MyVS2017BuildAgent"
$location = "westeurope"
$storageAccountName = "myvs2017buildagent"
$spDisplayName = "MyVS2017sp"
$spClientSecret = "MySecretPassword"

.\scripts\SetupPacker.ps1 -subscriptionId $subscriptionId -rgName $rgName -location $location -storageAccountName $storageAccountName -spDisplayName $spDisplayName -spClientSecret $spClientSecret
```

The script will output Subscription ID, Tenant ID, Resource Group Name, etc. Save these values, because they will be needed in next steps.

Next step: [Setup Azure DevOps project](Setup_Azure_DevOps_project.md)
