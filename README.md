# EncryptTheDisks
## Overview
Microsoft, on April 2nd, announced the [general availability for server-side encryption (SSE) with customer-managed keys (CMK) for Azure Managed Disks](<https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption>). EncryptTheDisk powershell script objective is to encrypt all the disks (OS+Data) for an existing VM.

## Prerequisites
The script expects the following object: 
- VM has already been created 
- Azure KeyVault has already been created
- The Key has already been imported inside the Azure KeyVault

## Get Started
The script taks in input the following parameters:
- SubscriptionID: 
- ResourceGroup:
- vmName:
- DiskEncryptionSetName:
- KeyVaultName:
- KeyName:
