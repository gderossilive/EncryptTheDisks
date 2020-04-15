# EncryptTheDisks
## Overview
Microsoft, il 2 Aprile 2020, ha annunciato la general availability per la [server-side encryption (SSE) con customer-managed keys (CMK) per gli Azure Managed Disks](<https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption>). Lo script powershell `EncryptTheDisk` è pensato per crittografare tutti i dischi (OS+Data) per una virtual machine esistente.

## Prerequisiti
Lo script, per poter funzionare correttamente, si aspetta che 
* Una `VM` esistente 
* Un `KeyVault` esistente
* Una `Chiave` per la cifratura dei dischi già presente all'interno dell'Azure Key Vault
* Un `Disk Encryption Set` esistente

## Come funziona
Lo script prende in imput i seguenti parametri
* `SubscriptionID`: L'ID della sottoscrizione che contine la VM
* `ResourceGroup`: Il nome del Resource Group che contiene la VM 
* `vmName`: Il nome della VM alla quale sono attacati di dischi da crittografare
* `KeyName`: Il nome della Customer Managed Key (CMK) utilizzata per crittografare i dischi 
* `KeyVaultName`: Il nome del Key Vault che contiene la Chiave (CMK)
* `DiskEncryptionSetName`: Il nome del Disk Encryption Set che utilizza la Chiave (CMK)

## Get started
### (Optional) Crea un ambiente di test
Per creare una ambiente di test dove lanciare `EncryptTheDisk`, si può utilizzare lo script `CreateDummyVM`. `CreateDummyVM` crea:
* 1 VM Linux
* 1 Azure KeyVault
* 1 Key nell'Azure Key Vault che verrà utilizzata per crittografare i dischi della VM e che simula la CMK
* 1 Azure Disk Encryption Set

Per lanciare lo script `CreateDummyVM`, basta digitare il comando seguente 
> PS >*./CreateDummyVM -SubscriptionID <11111111-2222-3333-4444-555555555555>*

### (Optional) Verifica lo stato di crittografia dei dischi
Per verificare lo stato attuale della crittografia dei dischi, basta lanciare lo script `CheckDisksEncryption`. Questo script prende in input