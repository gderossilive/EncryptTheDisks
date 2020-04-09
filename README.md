# EncryptTheDisks
## Overview
Microsoft, on April 2nd, announced the [general availability for server-side encryption (SSE) with customer-managed keys (CMK) for Azure Managed Disks](<https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption>). EncryptTheDisk powershell script objective is to encrypt all the disks (OS+Data) for an existing VM.

## Prerequisites
The script expects the following object
* VM has already been created 
* Azure KeyVault has already been created
* The Key has already been imported inside the Azure KeyVault
* The Disk Encryption Set has already been created

## How it works
The script takes in input the following parameters
* `SubscriptionID`: The ID of the existing subscription where the VM resides
* `ResourceGroup`: The name of the existing Resource Group where the VM resides
* `vmName`: The name of the existing VM where the disks needs encryption are attached
* `KeyName`: The name of the Customer Managed Key (CMK) used to encrypt the disks
* `KeyVaultName`: The name of existing KeyVault where the CMK is stored
* `DiskEncryptionSetName`: The name of the existing Disk Encryption Set where the CMK is used

## Get started
