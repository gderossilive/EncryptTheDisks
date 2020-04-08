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
    $ResourceGroup,   
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
    Connect-AzAccount
    $context = Get-AzSubscription -SubscriptionId $SubscriptionID -ErrorAction Stop
    Set-AzContext $context -ErrorAction Stop 
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
#Get the Key Vault
Try
{
    $KeyVault=Get-AzKeyVault -VaultName $KeyVaultName -ErrorAction Stop 

    #Get the key for disk encryption
    $key=Get-AzKeyVaultKey -VaultName $KeyVault.VaultName -Name $KeyName -ErrorAction Stop

    #Create a new DiskEcnryptionSet
    $config = New-AzDiskEncryptionSetConfig -Location $location -KeyUrl $key.Id -SourceVaultId $KeyVault.ResourceId -IdentityType 'SystemAssigned' -ErrorAction Stop
    $diskEncryptionSet=New-AzDiskEncryptionSet -ResourceGroupName $resourceGroup -Name $DiskEncryptionSetName -DiskEncryptionSet $config -ErrorAction Stop

    #Give access to the Azure Key Vault
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $diskEncryptionSet.Identity.PrincipalId -PermissionsToKeys wrapkey,unwrapkey,get -ErrorAction Stop
    New-AzRoleAssignment -ResourceName $keyVaultName -ResourceGroupName $ResourceGroup -ResourceType "Microsoft.KeyVault/vaults" -ObjectId $diskEncryptionSet.Identity.PrincipalId -RoleDefinitionName "Reader" -ErrorAction SilentlyContinue
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
    Stop-AzVM -ResourceGroupName $resourceGroup -Name $vmname -Force

    # Get the VM configuration
    $VM=Get-AzVM -ResourceGroupName $ResourceGroup -VM $vmName -ErrorAction Stop

    # Encrypt the OS disk
    $DiskConf=New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroup -DiskName $VM.StorageProfile.OsDisk.Name -ErrorAction Stop

    # Encrypt the Data Disks
    for($i=0;$i -lt $VM.StorageProfile.DataDisks.Count;$i++)
    {
        $DiskConf=New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroup -DiskName $VM.StorageProfile.DataDisks[$i].Name -ErrorAction Stop
        write-host "Data Disk Encryption: " $i  
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

write-host "Starting the VM..."  

# Re-Star the VM
Start-AzVM -ResourceGroupName $resourceGroup -Name $vmname

write-host "VM Started" 

