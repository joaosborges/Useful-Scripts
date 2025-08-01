<#
Author: João Borges 
Date: 21/02/2021
Version: 1.0
Description: This script will create a new image Version, delete the VM (and dependencies) and will exclude the old images from the latest
#>

#IMPORTANTE - RODAR SYSPREP ANTES DA EXECUCAO DESTE SCRIPT, bem como dealocar a VM
#%WINDIR%\system32\sysprep\sysprep.exe /generalize /shutdown /oobe

#Variables

$vmName = "" # VM that you'll take the image
$subscription = "" # Your Subscription ID
$tenantId = ""
$imageresourceGroup = "" # Image Resource Group Name
$vmresourceGroup = "" # Virtual Machine Resource Group Name
$sigName = "" #Shared Image Gallery Name
$imageDefinition = "" #Image that you'll create a new version
$imageVersion = "" # Version of the image

# DO NOT MAKE CHANGES AFTER HERE #

#Login on the azure CLI
#Write-Host "Login on the customer Tenant" -ForegroundColor Green
#$null = az login --tenant $tenantId

#Select the Subscription
Write-Host "Selecting the Azure Subscription $subscription" -ForegroundColor Green
az account set --subscription $subscription

Write-Output "#############################################################################"

# Vm Properties
Write-Host " Getting the VM properties" -ForegroundColor Green
$vmInfo = az vm show -g $vmresourceGroup -n $vmName -o json
$vmDetails = $vmInfo | ConvertFrom-json

# Deallocate the VM
Write-Host "Checking if the VM is deallocated" -ForegroundColor Gray

$powerStatus = az vm get-instance-view --name $vmDetails.name --resource-group $vmresourceGroup --query instanceView.statuses[1] -o json
$status = $powerStatus | ConvertFrom-Json

if ($status.displayStatus -eq "VM deallocated"){
    Write-Host "The VM $vmName already deallocated" -ForegroundColor Green
}else {
    Write-Host "The VM $vmName is running and will be deallocated" -ForegroundColor Red
    az vm deallocate -g $vmresourceGroup -n $vmName
}

Write-Output "#############################################################################"
# Generalize the VM on Azure
Write-Host "Starting the Generalize process" -ForegroundColor Gray
az vm generalize -g $vmresourceGroup -n $vmName

#Exclude old images from the latest
$allImages = az sig image-version list --resource-group $imageresourceGroup --gallery-name $sigName --gallery-image-definition $imageDefinition -o json
$images = $allImages | ConvertFrom-Json

foreach ($image in $images){
    $oldVersion = $image.name
    
    if ($image.publishingProfile.excludeFromLatest -eq "True"){
        Write-Host "Version $oldVersion already Disabled" -ForegroundColor Green
    }else {
        Write-Host "Setting the $oldVersion as exclude from latest..." -ForegroundColor Green
        az sig image-version update -g $imageresourceGroup --gallery-name $sigName --gallery-image-definition $imageDefinition --gallery-image-version $oldVersion --set publishingProfile.excludeFromLatest=true --no-wait
    }

    
}

Write-Output "#############################################################################"

# Publish de new Image Version
Write-Host "Publishing the new Image Version" -ForegroundColor Green
Write-Warning "The process can take over 30 Minutes! After started, you can not stop it. After finished, the VM and dependencies will be deleted"

az sig image-version create -g $imageresourceGroup --gallery-name $sigName --gallery-image-definition $imageDefinition --gallery-image-version $imageVersion --storage-account-type "Standard_ZRS" --managed-image $vmDetails.id 

Write-Host "Getting the New Image Status..." -ForegroundColor Gray
$ImageVersion = az sig image-version show --gallery-name $sigName --resource-group $imageresourceGroup --gallery-image-definition $imageDefinition --gallery-image-version $imageVersion
$imageDetails = $ImageVersion | ConvertFrom-Json 

if ($imageDetails.provisioningState -eq "Succeeded"){
    Write-Host "Process finished with Success!!!" -ForegroundColor Green
    
    Write-Host "The VM and dependencies will be deleted" -ForegroundColor Gray

    # Delete VM
    Write-Host "Deleting VM..." -ForegroundColor Gray
    az vm delete -n $vmName -g $vmresourceGroup --yes 

    # Delete O.S Disk
    Write-Host "Deleting O.S Disk..." -ForegroundColor Gray
    az disk delete -n $vmDetails.storageProfile.osDisk.name -g $vmresourceGroup --yes
    
    # Delete VM Nic
    Write-Host "Deleting Nic..." -ForegroundColor Gray
    az network nic delete -n $vmDetails.networkProfile.networkInterfaces.id.Split('/')[8] -g $vmresourceGroup

    Write-Host "Resources deleted with success" -ForegroundColor Green


}else {
    Write-Warning "Something goes Wrong, check the image Gallery" 
    #exit 1
}

Write-Output "#############################################################################"

