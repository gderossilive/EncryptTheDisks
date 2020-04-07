<#
 .SYNOPSIS
 EncryptTheDisks

 .DESCRIPTION
 EncryptTheDisks

 .PARAMETER SubscriptionID
 SubscriptionID

 .PARAMETER ResourceGroup
 ResourceGroup

 .PARAMETER vmName
 vmName

 .PARAMETER DiskEncryptionSetName
 DiskEncryptionSetName

 .PARAMETER KeyVaultName
 KeyVaultName

 .PARAMETER KeyName
 KeyName

.EXAMPLE
 C:\PS> EncryptTheDisks -SubscriptionID "11111111-2222-3333-4444-555555555555" -ResourceGroup "XXX" -vmName "XXX" -DiskEncryptionSetName "xxxx" -KeyVaultName "xxxx" -KeyName "xxx"
#>
[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $SubscriptionID,
    [Parameter()]
    [String]
    $ResourceGroup,   
    [Parameter()]
    [String]
    $vmName,  
    [Parameter()]
    [String]
    $DiskEncryptionSetName, 
    [Parameter()]
    [String]
    $KeyVaultName, 
    [Parameter()]
    [String]
    $KeyName
)

Connect-AzAccount

$context = Get-AzSubscription -SubscriptionId $SubscriptionID # 594cafab-484b-40b0-8336-f0a6042a8754
Set-AzContext $context

$seed=(Get-Random)

# Variables for common values
#$resourceGroup = "PCLRG$seed"
$location = "westeurope"
#$vmName = "PCLVM$seed"
#$DiskEncryptionSetName="PCLDiskEncryptionSet$seed"
#$KeyVaultName="PCLKeyVault$seed"
#$KeyName="Key$seed"
#$ServicePrincipalName="PCLSP$seed"

#------------------- Phase 2: Get KeyVault and the Key, Create Disk Encryption Set and  ----------------------------------------------
#Create a New Key Vault
$KeyVault=New-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -Location $location -EnableSoftDelete -EnablePurgeProtection

#Create a new key for disk encryption
$key=Add-AzKeyVaultKey -VaultName $KeyVault.VaultName -Name $KeyName -Destination 'Software'

#Create a new DiskEcnryptionSet
$config = New-AzDiskEncryptionSetConfig -Location $location -KeyUrl $key.Id -SourceVaultId $KeyVault.ResourceId -IdentityType 'SystemAssigned'
$diskEncryptionSet=New-AzDiskEncryptionSet -ResourceGroupName $resourceGroup -Name $DiskEncryptionSetName -DiskEncryptionSet $config;

#---------------- Phase 3: Disk Encryption ----------------------------------------------------------------------------------------------------------------------

# Stop the VM
Stop-AzVM -ResourceGroupName $resourceGroup -Name $vmname -Force

# Get the VM configuration
$VM=Get-AzVM -ResourceGroupName $ResourceGroup -VM $vmName

# Encrypt the OS disk
$DiskConf=New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroup -DiskName $VM.StorageProfile.OsDisk.Name

# Encrypt the Data Disks
for($i=0;$i -lt $VM.StorageProfile.DataDisks.Count;$i++)
{
    $DiskConf=New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroup -DiskName $VM.StorageProfile.DataDisks[$i].Name
    write-host "Data Disk Encryption: " $i  
}

write-host "Starting the VM..."  

# Re-Star the VM
Start-AzVM -ResourceGroupName $resourceGroup -Name $vmname

write-host "VM Started" 

