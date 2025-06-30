<#
.SYNOPSIS
Gets a value from the module's registry configuration.

.DESCRIPTION
Retrieves a registry value from the specified key within the module's registry configuration path.
Returns $null if the registry key or value doesn't exist.

.PARAMETER KeyName
The name of the registry key containing the value.

.PARAMETER ValueName
The name of the registry value to retrieve.

.EXAMPLE
Get-InventoryRegistryValue -KeyName "Configuration" -ValueName "DefaultPath"
Gets the "DefaultPath" value from the "Configuration" key in the module's registry path.

.OUTPUTS
[object]
Returns the registry value if it exists, $null otherwise.
#>
[CmdletBinding()]
[OutputType([object])]
param(
    [Parameter(Mandatory = $true)]
    [string]$KeyName,
    
    [Parameter(Mandatory = $true)]
    [string]$ValueName
)

try {
    $RegistryPath = Join-Path -Path $INVENTORY_CLI_REGISTRY_PATH -ChildPath $KeyName
    
    # First check if the key exists
    if (-not (Test-Path -Path $RegistryPath -PathType Container)) {
        Write-Verbose "Registry key does not exist: $RegistryPath"
        return $null
    }
    
    # Try to get the value
    $Value = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue
    
    if ($null -eq $Value) {
        Write-Verbose "Registry value '$ValueName' not found in key: $RegistryPath"
        return $null
    }
    
    $Result = $Value.$ValueName
    Write-Verbose "Retrieved registry value '$ValueName' from key '$RegistryPath': $Result"
    return $Result
}
catch {
    Write-Verbose "Error retrieving registry value: $($_.Exception.Message)"
    return $null
}
