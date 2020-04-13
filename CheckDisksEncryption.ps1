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
    $vmName 
)

$location = "westeurope"

Try
{
  Write-Host "Connecting to SubscriptioID:",$SubscriptionID,"..."
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


# Get the VM configuration
$VM=Get-AzVM -ResourceGroupName $ResourceGroupName -VM $vmName -ErrorAction Stop

# Checking encryption status for OS Disk
$disk=Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $VM.StorageProfile.OsDisk.Name
Write-Host "OS Disk Encryption Settings ->",$disk.Encryption.Type
   

# Checking encryption status for Data Disks
for($i=0;$i -lt $VM.StorageProfile.DataDisks.Count;$i++)
{
  $disk=Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $VM.StorageProfile.DataDisks[$i].Name
  Write-Host "Data Disk",$VM.StorageProfile.DataDisks[$i].Name,"Encryption Settings ->",$disk.Encryption.Type        
}
