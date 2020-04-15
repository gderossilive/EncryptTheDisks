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
    [Parameter(Mandatory=$True)]
    [String]
    $SubscriptionID,
    [Parameter(Mandatory=$True)]
    [String]
    $ResourceGroupName,   
    [Parameter(Mandatory=$True)]
    [String]
    $vmName,  
    [Parameter(Mandatory=$True)]
    [String]
    $DiskEncryptionSetName, 
    [Parameter(Mandatory=$True)]
    [String]
    $KeyVaultName, 
    [Parameter(Mandatory=$True)]
    [String]
    $KeyName
)

$location = "westeurope"

Try
{
  Write-Host "Connecting to SubscriptioID: ", $SubscriptionID," ..."
  $connect=Connect-AzAccount
  $context = Get-AzSubscription -SubscriptionId $SubscriptionID -ErrorAction Stop
  $setContext=Set-AzContext $context -ErrorAction Stop 
    
}
Catch
{
  $ErrorMessage = $_.Exception.Message
  $FailedItem = $_.Exception.ItemName
  Write-Host "Error. Please review your inputs"
  Write-Host "Error details: $ErrorMessage"
  Break
}

#------------------- Phase 1: Get KeyVault and the Key, Create Disk Encryption Set and  ----------------------------------------------

Try
{
  #Get the Key Vault and the key for disk encryption
  Write-Host "Connecting to Azure Key Vault ", $KeyVaultName," and getting the key ",$KeyName
  #Write-Host "Connecting to Azure Key Vault $KeyVaultName and getting the key $KeyName ..."
  $KeyVault=Get-AzKeyVault -VaultName $KeyVaultName -ErrorAction Stop 
  $key=Get-AzKeyVaultKey -VaultName $KeyVault.VaultName -Name $KeyName -ErrorAction Stop
    
  #Get the DiskEcnryptionSet
  Write-Host "Getting DiskEncryptionSet ", $DiskEncryptionSetName," ..." 
  $diskEncryptionSet=Get-AzDiskEncryptionSet -ResourceGroupName $resourceGroupName -Name $DiskEncryptionSetName -ErrorAction Stop

  #Give access to the Azure Key Vault
  Write-Host "Giving you required access to the KeyVault ..."
  #Write-Host "Giving you required access to the KeyVault ..."
  Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $diskEncryptionSet.Identity.PrincipalId -PermissionsToKeys wrapkey,unwrapkey,get -ErrorAction SilentlyContinue
  New-AzRoleAssignment -ResourceName $keyVaultName -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.KeyVault/vaults" -ObjectId $diskEncryptionSet.Identity.PrincipalId -RoleDefinitionName "Reader" -ErrorAction SilentlyContinue
}
Catch
{
  $ErrorMessage = $_.Exception.Message
  $FailedItem = $_.Exception.ItemName
  Write-Host "Error. Please review your inputs"
  Write-Host "Error details: $ErrorMessage"
  Break
}

#---------------- Phase 2: Disk Encryption ----------------------------------------------------------------------------------------------------------------------

Try
{
  # Stop the VM
  Write-Host "Stopping ", $vmname," ..."
  #Write-Host "Stopping $vmname ..."
  Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vmname -Force

  # Get the VM configuration
  $VM=Get-AzVM -ResourceGroupName $ResourceGroupName -VM $vmName -ErrorAction Stop

  # Encrypt the OS disk
  Write-Host -ForegroundColor Green "Encrypting OS Disk ..." 
  #Write-Host "Encrypting OS Disk ..."
  $DiskConf=New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $VM.StorageProfile.OsDisk.Name -ErrorAction Stop

  # Encrypt the Data Disks
  for($i=0;$i -lt $VM.StorageProfile.DataDisks.Count;$i++)
  {
    Write-host -ForegroundColor Green "Encrypting Data Disk ",$VM.StorageProfile.DataDisks[$i].Name," ..."
    $DiskConf=New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $VM.StorageProfile.DataDisks[$i].Name -ErrorAction Stop
        
  }
 }
  Catch
{
  $ErrorMessage = $_.Exception.Message
  $FailedItem = $_.Exception.ItemName
  Write-Host "Error. Please review your inputs"
  Write-Host "Error details: $ErrorMessage"
  Break
}

 

# Re-Star the VM
write-host "Starting the VM $vmname ..." 
Start-AzVM -ResourceGroupName $resourceGroupName -Name $vmname
write-host "VM Started" 

