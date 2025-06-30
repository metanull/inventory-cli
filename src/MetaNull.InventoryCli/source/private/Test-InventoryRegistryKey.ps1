<#
.SYNOPSIS
Tests if a registry key exists in the module's registry path.

.DESCRIPTION
Tests whether a specified registry key exists within the module's registry configuration path.
Returns $true if the key exists, $false otherwise.

.PARAMETER KeyName
The name of the registry key to test for existence.

.EXAMPLE
Test-InventoryRegistryKey -KeyName "Configuration"
Tests if the "Configuration" key exists in the module's registry path.
    
    .OUTPUTS
    [bool]
    Returns $true if the registry key exists, $false otherwise.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyName
    )
    
    try {
        $RegistryPath = Join-Path -Path $INVENTORY_CLI_REGISTRY_PATH -ChildPath $KeyName
        $KeyExists = Test-Path -Path $RegistryPath -PathType Container
    
    Write-Verbose "Testing registry key existence: $RegistryPath - Result: $KeyExists"
    return $KeyExists
}
catch {
    Write-Verbose "Error testing registry key: $($_.Exception.Message)"
    return $false
}
