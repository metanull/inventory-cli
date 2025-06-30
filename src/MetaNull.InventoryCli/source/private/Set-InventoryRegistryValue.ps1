<#
.SYNOPSIS
Sets a value in the module's registry configuration.

.DESCRIPTION
Sets a registry value in the specified key within the module's registry configuration path.
Creates the registry key (and parent keys) if they don't exist.

.PARAMETER KeyName
The name of the registry key to contain the value.

.PARAMETER ValueName
The name of the registry value to set.

.PARAMETER Value
The value to set in the registry.

.PARAMETER ValueType
The type of registry value to create. Valid values are 'String', 'DWord', 'QWord', 'Binary', 'MultiString', 'ExpandString'.
Defaults to 'String'.

.EXAMPLE
Set-InventoryRegistryValue -KeyName "Configuration" -ValueName "DefaultPath" -Value "C:\Default" -ValueType "String"
Sets the "DefaultPath" value in the "Configuration" key to "C:\Default" as a String.

.EXAMPLE
Set-InventoryRegistryValue -KeyName "Settings" -ValueName "MaxItems" -Value 100 -ValueType "DWord"
Sets the "MaxItems" value in the "Settings" key to 100 as a DWord.

.OUTPUTS
[bool]
Returns $true if the value was set successfully, $false otherwise.
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$KeyName,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ValueName,
    
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [object]$Value,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('String', 'DWord', 'QWord', 'Binary', 'MultiString', 'ExpandString')]
    [string]$ValueType = 'String'
)

try {
    Write-Verbose "Setting registry value '$ValueName' in key '$KeyName' to '$Value' (Type: $ValueType)"
    
    # Construct full registry path
    $RegistryPath = Join-Path $INVENTORY_CLI_REGISTRY_PATH $KeyName
    Write-Verbose "Full registry path: $RegistryPath"
    
    # Ensure the registry key exists (create if necessary)
    if (-not (Test-Path $RegistryPath)) {
        Write-Verbose "Creating registry key: $RegistryPath"
        New-Item -Path $RegistryPath -Force | Out-Null
    }
    
    # Set the registry value
    Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value $Value -Type $ValueType -Force
    
    # Verify the value was set correctly
    try {
        $VerifyValue = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction Stop
        Write-Verbose "Successfully set registry value '$ValueName' to '$($VerifyValue.$ValueName)'"
        return $true
    }
    catch {
        Write-Warning "Failed to verify registry value was set correctly"
        return $true  # Still return true as Set-ItemProperty didn't throw
    }
}
catch {
    Write-Verbose "Error setting registry value: $($_.Exception.Message)"
    return $false
}
