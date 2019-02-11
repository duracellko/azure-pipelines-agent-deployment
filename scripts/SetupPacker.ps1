param
(
    [string] $subscriptionId,
    [string] $rgName,
    [string] $location,
    [string] $storageAccountName,
    [string] $spDisplayName,
    [string] $spClientSecret
)

$context = Set-AzContext -Subscription $subscriptionId

# Create resource group and storage
New-AzResourceGroup -Name $rgName -Location $location
New-AzStorageAccount -ResourceGroupName $rgName -Name $storageAccountName -Location $location -SkuName "Standard_LRS"

# Create service principal and assign role
$credential = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential
$credential.Password = $spClientSecret
$credential.StartDate = [System.DateTime]::UtcNow
$credential.EndDate = $credential.StartDate.AddYears(10)
$sp = New-AzADServicePrincipal -DisplayName $spDisplayName -PasswordCredential $credential

$scope = '/subscriptions/' + $context.Subscription.Id
$spClientId = $sp.ApplicationId
$spObjectId = $sp.Id
Start-Sleep 40
New-AzRoleAssignment -ObjectId $spObjectId -RoleDefinitionName Contributor -Scope $scope

# Output result
$sub = Get-AzSubscription -SubscriptionId $subscriptionId
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
