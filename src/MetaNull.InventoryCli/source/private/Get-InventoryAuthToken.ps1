<#
.SYNOPSIS
Gets the stored authentication token from the module's registry configuration.

.DESCRIPTION
Retrieves the authentication token from the registry as a SecureString and converts it back to a regular string.
Returns $null if no token is stored or if there's an error accessing the token.

.EXAMPLE
Get-InventoryAuthToken
Gets the stored authentication token as a plain text string.

.OUTPUTS
[string]
The authentication token as a string, or $null if no token is stored.
#>
[CmdletBinding()]
[OutputType([string])]
param()

try {
    Write-Verbose "Retrieving authentication token from registry"
    
    # Get the token as a SecureString from registry
    $SecureTokenString = Get-InventoryRegistryValue -KeyName "Authentication" -ValueName "Token"
    
    if ($null -eq $SecureTokenString -or $SecureTokenString -eq '') {
        Write-Verbose "No authentication token found in registry"
        return $null
    }
    
    # Convert the stored string back to SecureString
    try {
        $SecureToken = ConvertTo-SecureString -String $SecureTokenString
        
        # Convert SecureString back to plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureToken)
        $PlainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        
        Write-Verbose "Successfully retrieved and decrypted authentication token"
        return $PlainToken
    }
    catch {
        Write-Verbose "Error decrypting stored token: $($_.Exception.Message)"
        return $null
    }
}
catch {
    Write-Verbose "Error retrieving authentication token: $($_.Exception.Message)"
    return $null
}
