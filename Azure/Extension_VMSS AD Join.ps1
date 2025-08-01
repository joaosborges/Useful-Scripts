<#
Author: João Borges 
Version: 1.0
Description: This script will create a extension on a VMSS to add instances on domain
#>


$Settings = @{
        "Name" = "contoso.com";
        "User" = "joindomain@contoso.com";
        "Restart" = "true";
        "Options" = 3;
        "OUPath" = "OU=Servidores,DC=contoso,DC=com"
    }

    $password = '' #joindomain user password

    $ProtectedSettings =  @{
            "Password" = $password
    }

    $rgName = "" #ResourceGroup name
    $scaleSetName = "" #vmss name
    $vmss = Get-AzVmss -ResourceGroupName $rgName -VMScaleSetName $scaleSetName
    $vmss = Add-AzVmssExtension -VirtualMachineScaleSet $vmss -Publisher "Microsoft.Compute" -Type "JsonADDomainExtension"  -TypeHandlerVersion 1.3  -Name "vmssjoindomain" -Setting $Settings -ProtectedSetting $ProtectedSettings -AutoUpgradeMinorVersion $true
    Update-AzVmss -ResourceGroupName $rgName  -Verbose -Name $scaleSetName -VirtualMachineScaleSet $vmss
