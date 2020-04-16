# EncryptTheDisks

## Overview

A partire dal 10 giugno 2017 ogni nuova VM creata su Azure, ha ogni disco crittografato con una chiave gestita da Microsoft (Platform-Managed Key). Il 2 Aprile 2020, Microsoft ha annunciato la general availability per la [server-side encryption (SSE) con customer-managed keys (CMK) per gli Azure Managed Disks](<https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disk-encryption>).
Questo vuol dire che non è più necessario installare un agent all'interno della VM per poter crittografare i dischi e che ogni utente può decidere se lasciare i dischi delle proprie VM crittografati con una chiave gestita da Microsoft (PMK) o sostituirla con una propria (CMK). 
Nel  caso in cui l'utente voglia utilizzare una propria chiave (CMK) questa può essere:

* Generata dall'utente all'interno di un Azure Key Vault sotto il suo controllo
* Generata dall'utente all'interno di un HSM nel suo datacenter e poi importata all'interno dell'Azure Key Vault sotto il suo controllo

Questa chiave (asimmetrica) generata dall'utente viene quindi utilizzata per crittografare una chiave simmetrica (AES based Data Encryption Key) con la tecnica dell'[envelop encryption] (<https://docs.microsoft.com/en-us/azure/storage/common/storage-client-side-encryption#encryption-and-decryption-via-the-envelope-technique>) ed utilizzata dagli Azure Managed Disk per gestire la crittografia dei dischi in modalità completamente trasparente.

E' necessario perciò concedere l'accesso all'Azure Key Vault che contiene la Chiave dell'utente da parte dei Managed Disks. Questo consente all'utente di revocare in ogni momento l'accesso ai dati da parte dei Managed Disks.

Lo script powershell `EncryptTheDisk` è pensato per crittografare tutti i dischi (OS+Data) per una virtual machine esistente.

## Prerequisiti

Lo script, per poter funzionare correttamente, si aspetta che

* Una `VM` esistente
* Un `KeyVault` esistente
* Una `Chiave` per la cifratura dei dischi già presente all'interno dell'Azure Key Vault
* Un `Disk Encryption Set` esistente

## Come funziona

Lo script prende in imput i seguenti parametri

* `SubscriptionID`: L'ID della sottoscrizione che contiene la VM
* `ResourceGroupName`: Il nome del Resource Group che contiene la VM 
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

Al termine dell'esecuzione, vengono restituti i comandi da 

### (Optional) Verifica lo stato di crittografia dei dischi

Per verificare lo stato attuale della crittografia dei dischi, basta lanciare lo script `CheckDisksEncryption`. Questo script prende in input

* `SubscriptionID`: L'ID della sottoscrizione che contiene la VM
* `ResourceGroupName`: Il nome del Resource Group che contiene la VM 
* `vmName`: Il nome della VM alla quale sono attacati di dischi da crittografare

Per lanciare lo script `CheckDisksEncryption`, basta digitare il comando seguente 
> PS >*./CheckDisksEncryption -SubscriptionID <11111111-2222-3333-4444-555555555555> -ResourceGroupName <Rource Group Name> -vmName <VM Name>*