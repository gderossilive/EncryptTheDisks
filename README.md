# EncryptTheDisks
## Overview
Microsoft, on April 2nd, announced the [general availability for server-side encryption (SSE) with customer-managed keys (CMK) for Azure Managed Disks](<https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption>). EncryptTheDisk powershell script objective is to encrypt all the disks (OS+Data) for an existing VM.

## Prerequisites
The script expects the following object: 
* VM has already been created 
* Azure KeyVault has already been created
* The Key has already been imported inside the Azure KeyVault

## Get Started
The script taks in input the following parameters:
* `SubscriptionID`: The ID of the subscription where the VM resides
* `ResourceGroup`: The Resource Group name where the VM resides
* `vmName`: The name of the VM where the disks needs encryption are attached
* `DiskEncryptionSetName`: The name of the Disk Encryption Set the script will create
* `KeyVaultName`: The KeyVault name where the Key to encrypt the disks is stored
* `KeyName`: The name of the Customer Managed Key used to encrypt the disk
