# Deletes all virtual machines from specified Azure resource group except the one specified.

param
(
    [string] $RGName,
    [string[]] $ExceptVMs,
    [bool] $RemovePublicAccess = $false
)

function ShouldRemoveResource([string] $name, [string[]] $excludeVMs) {
    foreach ($excludeVM in $excludeVMs) {
        if ($name.StartsWith($excludeVM, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $false
        }
    }

    return $true
}

function CointainsPort([System.Collections.Generic.IList[string]] $portRange, [int] $port) {
    $integerStyle = [System.Globalization.NumberStyles]::Integer
    $invariantCulture = [System.Globalization.CultureInfo]::InvariantCulture
    foreach ($rangePort in $portRange) {
        [int] $portValue = 0
        if ([int]::TryParse($rangePort, $integerStyle, $invariantCulture, [ref] $portValue)) {
            if ($portValue -eq $port) {
                return $true
            }
        }
    }

    return $false
}

# Unlink public IPs from NICs
if ($RemovePublicAccess) {
    Write-Output "Removing public IP links from NICs."
    $networkInterfaces = Get-AzureRmNetworkInterface -ResourceGroupName $RGName
    foreach ($networkInterface in $networkInterfaces) {
        Write-Output "Inspecting network interface: $($networkInterfaces.Name)"
        foreach ($ipConfiguration in $networkInterface.IpConfigurations) {
            Write-Output "Updating IP configuration: $($ipConfiguration.Name)"
            $ipConfiguration.PublicIpAddress = $null
        }

        Set-AzureRmNetworkInterface -NetworkInterface $networkInterface | Out-Null
    }
}

# Delete virtual machines
Write-Output "Searching for virtual machines."

$virtualMachines = Get-AzureRmVm -ResourceGroupName $RGName
$virtualMachines = $virtualMachines | Where-Object { $_.Name -notin $ExceptVMs }
foreach ($virtualMachine in $virtualMachines) {
    Write-Output "Removing virtual machine: $($virtualMachine.Name)"
    Remove-AzureRmVM -ResourceGroupName $RGName -Name $virtualMachine.Name -Force
}

# Delete network interfaces
Write-Output "Searching for network interfaces."
$NICs = Get-AzureRmNetworkInterface -ResourceGroupName $RGName
$NICs = $NICs | Where-Object { ShouldRemoveResource -name $_.Name -excludeVMs $ExceptVMs }
foreach ($NIC in $NICs) {
    Write-Output "Removing network interface: $($NIC.Name)"
    Remove-AzureRmNetworkInterface -ResourceGroupName $RGName -Name $NIC.Name -Force
}

# Delete public IP addresses
Write-Output "Searching for public IP addresses."

$publicIPs = Get-AzureRmPublicIpAddress -ResourceGroupName $RGName
if (-not $RemovePublicAccess) {
    $publicIPs = $publicIPs | Where-Object { ShouldRemoveResource -name $_.Name -excludeVMs $ExceptVMs }
}
foreach ($publicIP in $publicIPs) {
    Write-Output "Removing public IP address: $($publicIP.Name)"
    Remove-AzureRmPublicIpAddress -ResourceGroupName $RGName -Name $publicIP.Name -Force
}

# Delete network security groups
Write-Output "Searching for network security groups."
$networkSecurityGroups = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $RGName
$networkSecurityGroups = $networkSecurityGroups | Where-Object { ShouldRemoveResource -name $_.Name -excludeVMs $ExceptVMs }
foreach ($networkSecurityGroup in $networkSecurityGroups) {
    Write-Output "Removing network security group: $($networkSecurityGroup.Name)"
    Remove-AzureRmNetworkSecurityGroup -ResourceGroupName $RGName -Name $networkSecurityGroup.Name -Force
}

# Delete virtual networks
Write-Output "Searching for virtual networks."
$networks = Get-AzureRmVirtualNetwork -ResourceGroupName $RGName
$networks = $networks | Where-Object { ShouldRemoveResource -name $_.Name -excludeVMs $ExceptVMs }
foreach ($network in $networks) {
    Write-Output "Removing virtual network: $($network.Name)"
    Remove-AzureRmVirtualNetwork -ResourceGroupName $RGName -Name $network.Name -Force
}

# Delete key vaults
Write-Output "Searching for key vaults."
$keyVaults = Get-AzureRmKeyVault -ResourceGroupName $RGName
$keyVaults = $keyVaults | Where-Object { ShouldRemoveResource -name $_.VaultName -excludeVMs $ExceptVMs }
foreach ($keyVault in $keyVaults) {
    Write-Output "Removing key vault: $($keyVault.VaultName)"
    Remove-AzureRmKeyVault -ResourceGroupName $RGName -VaultName $keyVault.VaultName -Force -Confirm:$false
}

# Delete disks
Write-Output "Searching for disks."
$disks = Get-AzureRmDisk -ResourceGroupName $RGName
$disks = $disks | Where-Object { ShouldRemoveResource -name $_.Name -excludeVMs $ExceptVMs }
foreach ($disk in $disks) {
    Write-Output "Removing disk: $($disk.Name)"
    Remove-AzureRmDisk -ResourceGroupName $RGName -Name $disk.Name -Force
}

# Delete images
Write-Output "Searching for images."
$images = Get-AzureRmImage -ResourceGroupName $RGName
$images = $images | Where-Object { ShouldRemoveResource -name $_.Name -excludeVMs $ExceptVMs }
foreach ($image in $images) {
    Write-Output "Removing image: $($image.Name)"
    Remove-AzureRmImage -ResourceGroupName $RGName -Name $image.Name -Force
}

# Remove all network security rules with destination port 5986
$port = 5986

if ($RemovePublicAccess) {
    Write-Output "Removing network security rules with destination port $port."
    $networkSecurityGroups = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $RGName
    foreach ($networkSecurityGroup in $networkSecurityGroups) {
        Write-Output "Inspecting network group: $($networkSecurityGroup.Name)"
        $ruleConfigs = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSecurityGroup
        $ruleConfigs = $ruleConfigs | Where-Object { $_.Access -eq 'Allow' -and (CointainsPort -portRange $_.DestinationPortRange -port $port) }
        foreach ($ruleConfig in $ruleConfigs) {
            Write-Output "Removing network security rule: $($ruleConfig.Name)"
            $networkSecurityGroup = Remove-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSecurityGroup -Name $ruleConfig.Name
            Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $networkSecurityGroup | Out-Null
        }
    }
}
