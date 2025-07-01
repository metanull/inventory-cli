<#
.SYNOPSIS
Logs into the inventory API and stores the authentication token.

.DESCRIPTION
Authenticates with the inventory API using the provided credentials and stores the returned token
securely in the module's registry configuration. The token is encrypted as a SecureString.

.PARAMETER Credential
The credentials to use for authentication. Must contain username and password.

.PARAMETER ApiUrl
The API URL to authenticate against. If not provided, uses the configured API URL.

.EXAMPLE
$Cred = Get-Credential
Connect-InventoryApi -Credential $Cred
Authenticates with the API using the provided credentials.

.EXAMPLE
Connect-InventoryApi -Credential $Cred -ApiUrl "https://api.example.com"
Authenticates with a specific API URL.

.OUTPUTS
[bool]
Returns $true if authentication was successful, $false otherwise.
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [string]$ApiUrl
)

try {
    Write-Verbose "Starting authentication process"

    # Get API URL if not provided
    if ([string]::IsNullOrEmpty($ApiUrl)) {
        $ApiUrl = Get-InventoryApiUrl
        Write-Verbose "Using configured API URL: $ApiUrl"
    }

    # Prepare authentication request
    $AuthEndpoint = "$ApiUrl/mobile/acquire-token"
    $AuthBody = @{
        email = $Credential.UserName
        password = $Credential.GetNetworkCredential().Password
        device_name = "$env:COMPUTERNAME-PowerShell"
        wipe_tokens = $false
    } | ConvertTo-Json

    Write-Verbose "Attempting authentication with endpoint: $AuthEndpoint"

    # Make authentication request
    try {
        $Response = Invoke-RestMethod -Uri $AuthEndpoint -Method POST -Body $AuthBody -ContentType "application/json" -ErrorAction Stop

        if ($Response -and $Response -is [string] -and $Response.Length -gt 0) {
            Write-Verbose "Authentication successful, storing token"

            # Convert token to SecureString and store it
            $SecureToken = ConvertTo-SecureString -String $Response -AsPlainText -Force
            $EncryptedToken = ConvertFrom-SecureString -SecureString $SecureToken

            $Result = Set-InventoryRegistryValue -KeyName "Authentication" -ValueName "Token" -Value $EncryptedToken -ValueType "String"

            if ($Result) {
                Write-Verbose "Token stored successfully in registry"
                return $true
            } else {
                Write-Error "Failed to store authentication token"
                return $false
            }
        } else {
            Write-Error "Authentication response did not contain a valid token"
            return $false
        }
    }
    catch {
        Write-Error "Authentication failed: $($_.Exception.Message)"
        return $false
    }
}
catch {
    Write-Error "Error during authentication process: $($_.Exception.Message)"
    return $false
}
