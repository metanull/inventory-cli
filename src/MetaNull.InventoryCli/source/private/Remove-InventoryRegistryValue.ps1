<#
.SYNOPSIS
Removes a registry value from the module's registry configuration.

.DESCRIPTION
Removes a specific value from a registry key under the module's registry path.
This function provides a consistent interface for registry value removal operations.

.PARAMETER KeyName
The name of the registry key under the module's registry path.

.PARAMETER ValueName
The name of the registry value to remove.

.EXAMPLE
Remove-InventoryRegistryValue -KeyName "Authentication" -ValueName "Token"
Removes the Token value from the Authentication registry key.

.OUTPUTS
[bool]
Returns $true if the value was removed successfully, $false otherwise.
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory = $true)]
    [string]$KeyName,

    [Parameter(Mandatory = $true)]
    [string]$ValueName
)

try {
    Write-Verbose "Removing registry value '$ValueName' from key '$KeyName'"

    # Check if the registry key exists
    if (-not (Test-InventoryRegistryKey -KeyName $KeyName)) {
        Write-Verbose "Registry key '$KeyName' does not exist, nothing to remove"
        return $true
    }

    # Build the full registry path
    $RegistryPath = Join-Path $INVENTORY_CLI_REGISTRY_PATH $KeyName
    Write-Verbose "Registry path: $RegistryPath"

    # Check if the value exists
    try {
        Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction Stop | Out-Null
        Write-Verbose "Found existing value '$ValueName', proceeding with removal"
    }
    catch {
        Write-Verbose "Registry value '$ValueName' does not exist in key '$KeyName', nothing to remove"
        return $true
    }

    # Remove the registry value
    Remove-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction Stop
    Write-Verbose "Successfully removed registry value '$ValueName' from key '$KeyName'"

    return $true
}
catch {
    Write-Error "Failed to remove registry value '$ValueName' from key '$KeyName': $($_.Exception.Message)"
    return $false
}
