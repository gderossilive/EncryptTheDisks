<#
 .SYNOPSIS
 EncryptTheDisks

 .DESCRIPTION
 EncryptTheDisks

 .PARAMETER SubscriptionID
 SubscriptionID

.EXAMPLE
 C:\PS> CreateDummyVM -SubscriptionID "11111111-2222-3333-4444-555555555555"
#>
[CmdletBinding()]
param ( 
    [Parameter()]
    [String]
    $SubscriptionID
)

Connect-AzAccount

$context = Get-AzSubscription -SubscriptionId $SubscriptionID
Set-AzContext $context

$seed=(Get-Random)

# Variables for common values
$resourceGroup = "PCLRG$seed"
$location = "westeurope"
$vmName = "PCLVM$seed"
$DiskEncryptionSetName="PCLDiskEncryptionSet$seed"
$KeyVaultName="PCLKeyVault$seed"
$KeyName="Key$seed"
$ServicePrincipalName="PCLSP$seed"

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

$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_B8ms
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

Write-host "Your public IP address is $($pip.IpAddress)"

#------------------- Phase 2: Create KeyVault, Disk Encryption Set and Service Principal giving access to the AKV ----------------------------------------------
#Create a New Key Vault
$KeyVault=New-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -Location $location -EnableSoftDelete -EnablePurgeProtection

#Create a new key for disk encryption
$key=Add-AzKeyVaultKey -VaultName $KeyVault.VaultName -Name $KeyName -Destination 'Software'

Write-Host "Type EncryptTheDisks -SubscriptionID $SubscriptionID -ResourceGroup $resourcegroup -vmName $vmName -DiskEncryptionSetName $DiskEncryptionSetName -KeyVaultName $KeyVaultName -KeyName $KeyName"


