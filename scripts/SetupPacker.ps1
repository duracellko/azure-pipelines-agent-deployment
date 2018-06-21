param
(
    [string] $subscriptionId,
    [string] $rgName,
    [string] $location,
    [string] $storageAccountName,
    [string] $spDisplayName,
    [string] $spClientSecret
)

Set-AzureRmContext -Subscription $subscriptionId
New-AzureRmResourceGroup -Name $rgName -Location $location
New-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName $storageAccountName -Location $location -SkuName "Standard_LRS"
$sp = New-AzureRmADServicePrincipal -DisplayName $spDisplayName -Password (ConvertTo-SecureString $spClientSecret -AsPlainText -Force)
$spAppId = $sp.ApplicationId
$spClientId = $sp.ApplicationId
$spObjectId = $sp.Id
Start-Sleep 40
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $spAppId
$sub = Get-AzureRmSubscription -SubscriptionId $subscriptionId
$tenantId = $sub.TenantId
$result = @(
    ""
    "Note this variable-setting script for running Packer with these Azure resources in the future:"
    "=============================================================================================="
    "`$spClientId = `"$spClientId`""
    "`$spClientSecret = `"$spClientSecret`""
    "`$subscriptionId = `"$subscriptionId`""
    "`$tenantId = `"$tenantId`""
    "`$spObjectId = `"$spObjectId`""
    "`$location = `"$location`""
    "`$rgName = `"$rgName`""
    "`$storageAccountName = `"$storageAccountName`""
    ""
)

Write-Output $result
