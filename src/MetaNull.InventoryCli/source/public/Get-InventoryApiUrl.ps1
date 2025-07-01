<#
.SYNOPSIS
Gets the API URL for the inventory system.

.DESCRIPTION
Retrieves the API URL from the module's registry configuration. If no URL is configured,
returns the default value of 'http://127.0.0.1:8000'.

.EXAMPLE
Get-InventoryApiUrl
Returns the configured API URL or the default value if not configured.

.OUTPUTS
[string]
The API URL as a string.
#>
[CmdletBinding()]
[OutputType([string])]
param()

    try {
        Write-Verbose "Retrieving API URL from registry"

        # Try to get the URL from registry
        $ApiUrl = Get-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl"

        if ($null -eq $ApiUrl) {
            Write-Verbose "API URL not found in registry, returning default value"
            $ApiUrl = "http://127.0.0.1:8000"
        }

        Write-Verbose "API URL: $ApiUrl"
        return $ApiUrl
    }
    catch {
        Write-Warning "Error retrieving API URL: $($_.Exception.Message)"
    Write-Verbose "Returning default API URL due to error"
    return "http://127.0.0.1:8000"
}
