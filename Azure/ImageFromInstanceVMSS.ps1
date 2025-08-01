<#
Author: João Borges 
Date: 21/02/2023
Version: 1.0
Description: This script will create a new image Version from instance of a virtual machine scale set (VMSS)
#>

#IMPORTANTE - RODAR SYSPREP ANTES DA EXECUCAO DESTE SCRIPT
#%WINDIR%\system32\sysprep\sysprep.exe /generalize /shutdown /oobe


#Azure Login Parameters
#$tenantId = ""
#$subscriptionId = ""

#Instance Parameters
$vmssName = "" #VMSSName
$resourceGroupName = "" #VMSS ResourceGroup
$snapshotName = "" #Name of the Snapshot
$instanceId = 4 #Instance that you want to take a snapshot

#Azure Compute gallery Parameters
$galleryName = "" #Azure Compute Gallery Name
$galleryImageDefinition = "" #Image Definition Name
$imageVersion = "" #Version Id, Example -> 20.30.40

## END OF THE VARIABLE SECTION ##

#Login on Azure Account
#$null = az login --tenant $tenantId
#$null = az account set --subscription $subscriptionId

#Getting VMSS
$vmssConfig = az vmss show --name $vmssName --resource-group $resourceGroupName --instance-id $instanceId | ConvertFrom-Json

#Creating Snapshot
$null = az snapshot create -g $resourceGroupName -n $snapshotName --source $vmssConfig.storageProfile.osDisk.managedDisk.id

Start-Sleep -Seconds 45

#Creating Managed Image
$snapshot = az snapshot show --name $snapshotName --resource-group $resourceGroupName | ConvertFrom-Json
az sig image-version create --resource-group $resourceGroupName --gallery-name $galleryName --gallery-image-definition $galleryImageDefinition --gallery-image-version $imageVersion --os-snapshot $snapshot.id

#Deleting Instance After creating the Snapshot and Sysprep
az vmss delete-instances --name $vmssName --resource-group $resourceGroupName --instance-id $instanceId