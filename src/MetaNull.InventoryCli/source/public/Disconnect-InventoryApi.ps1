<#
.SYNOPSIS
Logs out from the inventory API and removes the stored authentication token.

.DESCRIPTION
Removes the stored authentication token from the module's registry configuration.
Optionally notifies the API server about the logout.

.PARAMETER ApiUrl
The API URL to send logout notification to. If not provided, uses the configured API URL.

.PARAMETER SkipServerNotification
If specified, skips notifying the API server about the logout and only removes the local token.

.EXAMPLE
Disconnect-InventoryApi
Logs out and removes the stored token, notifying the API server.

.EXAMPLE
Disconnect-InventoryApi -SkipServerNotification
Removes the stored token without notifying the API server.

.OUTPUTS
[bool]
Returns $true if the token was removed successfully, $false otherwise.
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory = $false)]
    [string]$ApiUrl,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipServerNotification
)

try {
    Write-Verbose "Starting logout process"
    
    # Get the current token before removing it
    $CurrentToken = Get-InventoryAuthToken
    
    if (-not $SkipServerNotification -and $null -ne $CurrentToken) {
        # Get API URL if not provided
        if ([string]::IsNullOrEmpty($ApiUrl)) {
            $ApiUrl = Get-InventoryApiUrl
            Write-Verbose "Using configured API URL: $ApiUrl"
        }
        
        # Notify API server about logout
        try {
            $LogoutEndpoint = "$ApiUrl/auth/logout"
            $Headers = @{
                "Authorization" = "Bearer $CurrentToken"
            }
            
            Write-Verbose "Notifying API server about logout: $LogoutEndpoint"
            Invoke-RestMethod -Uri $LogoutEndpoint -Method POST -Headers $Headers -ErrorAction Stop
            Write-Verbose "Successfully notified API server about logout"
        }
        catch {
            Write-Warning "Failed to notify API server about logout: $($_.Exception.Message)"
            # Continue with local token removal even if server notification fails
        }
    }
    
    # Remove the token from registry
    Write-Verbose "Removing authentication token from registry"
    
    # Use the registry helper function to remove the token
    $RemovalResult = Remove-InventoryRegistryValue -KeyName "Authentication" -ValueName "Token"
    
    if ($RemovalResult) {
        Write-Verbose "Successfully removed authentication token from registry"
        return $true
    } else {
        Write-Error "Failed to remove authentication token from registry"
        return $false
    }
}
catch {
    Write-Error "Error during logout process: $($_.Exception.Message)"
    return $false
}
