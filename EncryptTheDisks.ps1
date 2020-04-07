Connect-AzAccount

$context = Get-AzSubscription -SubscriptionId 594cafab-484b-40b0-8336-f0a6042a8754
Set-AzContext $context

$seed=(Get-Random)

# Variables for common values
$resourceGroup = "GdrRG$seed"
$location = "westeurope"
$vmName = "GdrVM$seed"
$DiskEncryptionSetName="GdrDiskEncryptionSet$seed"
$KeyVaultName="GDRKeyVault$seed"
$KeyName="Key$seed"
$ServicePrincipalName="GdrSP$seed"

New-AzResourceGroup -Name $resourceGroup -Location $location

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create a virtual network card and associate with public IP address
$nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

# Create a virtual machine configuration
#$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_B8ms | `
#    Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
#    Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
#    -Skus 2016-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nic.Id

$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_DS14_v2 #Standard_B8ms
$OsDisk=Set-AzVMOperatingSystem -VM $vmconfig -Windows -ComputerName $vmName -Credential $cred -
$n=Get-Random -Maximum 5
$i=0
do{
    $DataDisk=Add-AzVMDataDisk -VM $vmconfig -Name "MyVM-data$i" -DiskSizeInGB 1000 -CreateOption Empty -Lun $i
    #$i
    $i++
} While ($n -gt $i)


$VmSourceImage=Set-AzVMSourceImage -VM $vmConfig -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nic.Id


# Create a virtual machine
$VM=New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig

# Fill each disk with 800GB of dummy data 
Set-AzVMCustomScriptExtension -ResourceGroupName $resourceGroup `
    -VMName $vmName `
    -Location $location `
    -FileUri https://raw.githubusercontent.com/gderossilive/FillTheDisks/master/FillTheDisk.ps1 `
    -Run 'FillTheDisk.ps1 800' `
    -Name DemoScriptExtension

Write-host "Your public IP address is $($pip.IpAddress)"

#------------------- Phase 2: Create KeyVault, Disk Encryption Set and Service Principal giving access to the AKV ----------------------------------------------
#Create a New Key Vault
$KeyVault=New-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -Location $location -EnableSoftDelete -EnablePurgeProtection

#Create a new key for disk encryption
$key=Add-AzKeyVaultKey -VaultName $KeyVault.VaultName -Name $KeyName -Destination 'Software'

#Create a new DiskEcnryptionSet
$config = New-AzDiskEncryptionSetConfig -Location $location -KeyUrl $key.Id -SourceVaultId $KeyVault.ResourceId -IdentityType 'SystemAssigned'
$des=New-AzDiskEncryptionSet -ResourceGroupName $resourceGroup -Name $DiskEncryptionSetName -DiskEncryptionSet $config;

#Create the Service Principal & give access
$identity= New-AzADServicePrincipal -DisplayName $ServicePrincipalName 

#Give access to the Azure Key Vault
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $des.Identity.PrincipalId -PermissionsToKeys wrapkey,unwrapkey,get
New-AzRoleAssignment -ResourceName $keyVaultName -ResourceGroupName $ResourceGroup -ResourceType "Microsoft.KeyVault/vaults" -ObjectId $des.Identity.PrincipalId -RoleDefinitionName "Reader"


#---------------- Phase 3: Disk Encryption ----------------------------------------------------------------------------------------------------------------------

$resourceGroup 
$vmName 
$DiskEncryptionSetName
$ServicePrincipalName

# Get the Service Principal identity 
$identity = Get-AzADServicePrincipal -DisplayName $ServicePrincipalName
$svcPrincipalCreds = New-AzADSpCredential -ObjectId $identity.Id
$creds = New-Object System.Management.Automation.PSCredential($identity.ApplicationId, $svcPrincipalCreds.Secret)

# Stop the VM
Stop-AzVM -ResourceGroupName $resourceGroup -Name $vmname -Force

# Get the VM configuration
$VM=Get-AzVM -ResourceGroupName $ResourceGroup -VM $vmName

# Get the Disk Encryption Set configuration
$diskEncryptionSet=Get-AzDiskEncryptionSet -ResourceGroupName $ResourceGroup -Name $DiskEncryptionSetName

# Login as Service Principal identity
Connect-AzAccount -Credential $creds -ServicePrincipal -Tenant $context.TenantId

$StartTime = $(get-date)

# Encrypt the OS disk
$DiskConf=New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroup -DiskName $VM.StorageProfile.OsDisk.Name
$elapsedTime = $(get-date) - $StartTime 
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
write-host "OS Disk Encryption: " $totalTime 

# Encrypt the Data Disks
for($i=0;$i -lt $VM.StorageProfile.DataDisks.Count;$i++)
{
    $DiskConf=New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroup -DiskName $VM.StorageProfile.DataDisks[$i].Name
    $elapsedTime = $(get-date) - $StartTime 
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    $totalTime
    write-host "Data Disk Encryption: " $totalTime  
}

$elapsedTime = $(get-date) - $StartTime 
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
$totalTime 
write-host "Total Disks Encryption: " $totalTime 

# Re-Star the VM
Start-AzVM -ResourceGroupName $resourceGroup -Name $vmname

#CleanUp
#Remove-AzResourceGroup -Name $resourceGroup


