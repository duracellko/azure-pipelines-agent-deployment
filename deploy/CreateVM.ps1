# CreatesAzure VM in specified resource group.
# Additionally WinRM is setup so that it is possible to install VSTS build agent remotely.

param
(
    [string] $RGName,
    [string] $Location,
    [string] $VHDUriFile,
    [string] $VMName,
    [string] $Username,
    [string] $Password,
    [string] $ServicePrincipalObjectId,
	[string] $VMSize = 'Standard_B2S'
)
    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)

try {
	# Read VHD URI from image.txt file
	$osDiskUriPrefix = 'OSDiskUri:'
	$vhdUriFileContent = Get-Content -Path $VHDUriFile
	$vhdUriFileContent = @($vhdUriFileContent)
	$VHDUri = $null
	foreach ($vhdUriFileLine in $vhdUriFileContent) {
		if ($vhdUriFileLine.StartsWith($osDiskUriPrefix, [StringComparison]::OrdinalIgnoreCase))
		{
			$VHDUri = $vhdUriFileLine.Substring($osDiskUriPrefix.Length).Trim()
		}
	}

	if ([string]::IsNullOrEmpty($VHDUri)) {
		throw "VHD URI was not found in image.txt"
	}

	Write-Output "VHD URI: $VHDUri"

    # Create private key for WinRM
    $fullDnsName = "$VMName.$Location.cloudapp.azure.com"
    $tempPath = [System.IO.Path]::GetTempPath()
    $privateKeyPath = Join-Path $tempPath "WinRM.pfx"
    $privateKeyPasswordPlain = (New-Guid).ToString('n')
    $privateKeyPassword = ConvertTo-SecureString -String $privateKeyPasswordPlain -AsPlainText -Force
    $privateKey = New-SelfSignedCertificate -DnsName $fullDnsName -CertStoreLocation 'Cert:\CurrentUser\My'
    Export-PfxCertificate -Cert $privateKey -FilePath $privateKeyPath -Password $privateKeyPassword -Force
    Remove-Item "Cert:\CurrentUser\My\$($privateKey.Thumbprint)" -Force

    # Store private key in Azure Key Vault
    $args = @{
        VaultName = $VMName + 'KeyVault'
        ResourceGroupName = $RGName
        Location = $Location
        EnabledForDeployment = $true
    }
    $keyVault = New-AzureRmKeyVault @args
    Write-Output "Created Key Vault: $($keyVault.ResourceId)"

    Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ResourceGroupName $RGName -ObjectId $ServicePrincipalObjectId -PermissionsToSecrets Get, List, Set, Delete -Confirm:$false

    $privateKeyBytes = Get-Content $privateKeyPath -Encoding Byte
    $privateKeyBase64 = [System.Convert]::ToBase64String($privateKeyBytes)
    $privateKeyJson = @{
        data = $privateKeyBase64
        dataType = 'pfx'
        password = $privateKeyPasswordPlain
    }
    $privateKeyJson = ConvertTo-Json -InputObject $privateKeyJson
    $privateKeyBytes = [System.Text.Encoding]::UTF8.GetBytes($privateKeyJson)
    $privateKeyBase64 = [System.Convert]::ToBase64String($privateKeyBytes)
    $privateKeySecret = ConvertTo-SecureString -String $privateKeyBase64 -AsPlainText -Force

    $keyVaultKeyName = $VMName + '-WinRM'
    $keyVaultWinRM = Set-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name $keyVaultKeyName -SecretValue $privateKeySecret
    Write-Output "Added Key Vault key: $($keyVaultWinRM.Id)"

    Remove-Item $privateKeyPath -Force

    # Create a subnet configuration
    $args = @{
        Name = $VMName + 'Subnet'
        AddressPrefix = '192.168.1.0/24'
    }
    $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig @args

    # Create a virtual network
    $args = @{
        Name = $VMName + 'Net'
        ResourceGroupName = $RGName
        Location = $Location
        AddressPrefix = '192.168.0.0/16'
        Subnet = $subnetConfig
    }
    $vnet = New-AzureRmVirtualNetwork @args
    Write-Output "Created Virtual Network: $($vnet.Id)"

    # Create a public IP address and specify a DNS name
    $args = @{
        Name = $VMName + 'PublicIP'
        ResourceGroupName = $RGName
        Location = $Location
        AllocationMethod = 'Dynamic'
        IdleTimeoutInMinutes = 4
    }
    $publicIP = New-AzureRmPublicIpAddress @args
    Write-Output "Created Public IP: $($publicIP.Id)"

    # Create an inbound network security group rule for port 5986 - WinRM: HTTPS
    $args = @{
        Name = 'WinRM'
        Protocol = 'Tcp'
        Direction = 'Inbound'
        SourceAddressPrefix = '*'
        SourcePortRange = '*'
        DestinationAddressPrefix = '*'
        DestinationPortRange = 5986
        Access = 'Allow'
        Priority = 1001
    }
    $nsgRuleWRM = New-AzureRmNetworkSecurityRuleConfig @args

    # Create a network security group
    $args = @{
        Name = $VMName + 'NSG'
        ResourceGroupName = $RGName
        Location = $Location
        SecurityRules = $nsgRuleWRM
    }
    $nsg = New-AzureRmNetworkSecurityGroup @args
    Write-Output "Created Network Security Group: $($nsg.Id)"

    # Create a virtual network card and associate with public IP address and NSG
    $args = @{
        Name = $VMName + 'NIC'
        ResourceGroupName = $RGName
        Location = $Location
        SubnetId = $vnet.Subnets[0].Id
        NetworkSecurityGroupId = $nsg.Id
        PublicIpAddressId = $publicIP.Id
    }
    $nic = New-AzureRmNetworkInterface @args
    Write-Output "Created Network Interface: $($nic.Id)"

    # Define the image created by Packer
    $imageConfig = New-AzureRmImageConfig -Location $Location
    $imageConfig = Set-AzureRmImageOsDisk -Image $imageConfig -OsType Windows -OsState Generalized -BlobUri $VHDUri -StorageAccountType PremiumLRS
    $imageName = $VMName + 'Image'
    $image = New-AzureRmImage -ImageName $imageName -ResourceGroupName $RGName -Image $imageConfig
    Write-Output "Created Image: $($image.Id)"

    # Create a virtual machine configuration
    $vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
    $vmConfig = $vmConfig | Set-AzureRmVMOperatingSystem -Windows -ComputerName $VMName -Credential $cred -ProvisionVMAgent -WinRMHttps -WinRMCertificateUrl $keyVaultWinRM.Id
    $vmConfig = $vmConfig | Set-AzureRmVMSourceImage -Id $image.Id
    $vmConfig = $vmConfig | Add-AzureRmVMSecret -SourceVaultId $keyVault.ResourceId -CertificateStore 'My' -CertificateUrl $keyVaultWinRM.Id
    $vmConfig = $vmConfig | Add-AzureRmVMNetworkInterface -Id $nic.Id
    $vmConfig = $vmConfig | Add-AzureRmVMDataDisk -DiskSizeInGB 64 -CreateOption Empty -Lun 0

    New-AzureRmVM -ResourceGroupName $RGName -Location $Location -VM $vmConfig
    $vm = Get-AzureRmVM -ResourceGroupName $RGName -Name $VMName
    Write-Output "Created Virtual Machine: $($vm.Id)"
}
catch {
    throw
}