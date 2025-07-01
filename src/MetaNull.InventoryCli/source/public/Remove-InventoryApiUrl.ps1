<#
.SYNOPSIS
Removes the API URL configuration from the inventory system.

.DESCRIPTION
Removes the API URL from the module's registry configuration. After removal,
Get-InventoryApiUrl will return the default value.

.EXAMPLE
Remove-InventoryApiUrl
Removes the API URL configuration from the registry.

.OUTPUTS
[bool]
Returns $true if the URL was removed successfully, $false otherwise.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([bool])]
param()

    try {
        Write-Verbose "Removing API URL from registry configuration"

        if ($PSCmdlet.ShouldProcess("API URL configuration", "Remove")) {
            # Check if the value exists first
            $CurrentUrl = Get-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl"

            if ($null -eq $CurrentUrl) {
                Write-Verbose "API URL is not currently configured"
                return $true
            }

            # Remove the value from registry
            try {
                $RegistryPath = Join-Path -Path $INVENTORY_CLI_REGISTRY_PATH -ChildPath "Configuration"
                Remove-ItemProperty -Path $RegistryPath -Name "ApiUrl" -ErrorAction Stop
                Write-Verbose "Successfully removed API URL from registry"
                return $true
            }
            catch {
                Write-Warning "Failed to remove API URL from registry: $($_.Exception.Message)"
                return $false
            }
        }

    return $true
}
catch {
    Write-Error "Error removing API URL: $($_.Exception.Message)"
    return $false
}
