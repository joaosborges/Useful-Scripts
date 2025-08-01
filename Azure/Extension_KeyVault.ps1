<#
Author: João Borges 
Version: 1.0
Description: This script will create a extension on a VMSS to install a certificate on the instance
#>


$vmssName = ""
$rgName = "A"

$cert = ""
$store = "MY"
$location = "LocalMachine"
$pollInSec = "86400"

# Build settings
$settings = @{
    secretsManagementSettings = @{
        pollingIntervalInS = "86400"
        certificateStoreName = $store
        certificateStoreLocation =  $location
        observedCertificates = @($cert)
    }
}
$extName = "KeyVaultForWindows"
$extPublisher = "Microsoft.Azure.KeyVault"
$extType = "KeyVaultForWindows"



# Add Extension to VMSS#
$vmss = Get-AzVmss -ResourceGroupName $rgName -VMScaleSetName $vmssName
Add-AzVmssExtension -VirtualMachineScaleSet $vmss  -Name $extName -Publisher $extPublisher -Type $extType -TypeHandlerVersion "1.0" -Setting $settings

# Start the deployment
Update-AzVmss -ResourceGroupName $rgName -VMScaleSetName $vmssName -VirtualMachineScaleSet $vmss


