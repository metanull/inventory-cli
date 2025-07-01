<#
.SYNOPSIS
Sets the API URL for the inventory system.

.DESCRIPTION
Stores the API URL in the module's registry configuration. If no URL is provided,
sets the default value of 'http://127.0.0.1:8000'.

.PARAMETER Url
The API URL to set. If not provided, defaults to 'http://127.0.0.1:8000'.

.EXAMPLE
Set-InventoryApiUrl
Sets the API URL to the default value 'http://127.0.0.1:8000'.

.EXAMPLE
Set-InventoryApiUrl -Url "https://api.mycompany.com:8443"
Sets the API URL to the specified value.

.OUTPUTS
[bool]
Returns $true if the URL was set successfully, $false otherwise.
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Url = "http://127.0.0.1:8000"
)

    try {
        Write-Verbose "Setting API URL to: $Url"

        # Validate URL format
        try {
            $Uri = [System.Uri]::new($Url)
            if ($Uri.Scheme -notin @('http', 'https')) {
                throw "URL must use http or https scheme"
            }
        }
        catch {
            Write-Error "Invalid URL format: $Url. Error: $($_.Exception.Message)"
            return $false
        }

        # Set the URL in registry
        $Result = Set-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl" -Value $Url -ValueType "String"

        if ($Result) {
            Write-Verbose "Successfully set API URL to: $Url"
        } else {
            Write-Warning "Failed to set API URL in registry"
        }

    return $Result
}
catch {
    Write-Error "Error setting API URL: $($_.Exception.Message)"
    return $false
}
