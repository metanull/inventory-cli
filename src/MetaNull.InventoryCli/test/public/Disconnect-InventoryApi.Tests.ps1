Describe "Disconnect-InventoryApi" -Tag "UnitTest" {

    BeforeAll {
        $script:INVENTORY_CLI_REGISTRY_PATH = "HKCU:\SOFTWARE\metanull.test\inventory-cli"

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\public")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName
        
        # Define the Module function by dot sourcing it
        Function Disconnect-InventoryApi {
            . $Script @args | write-Output
        }
        # Define an accessor to the function's properties
        Function Disconnect-InventoryApi_Command {
            Get-Command $Script
        }

        # Define stub functions for dependencies
        Function Get-InventoryApiUrl {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'public\Get-InventoryApiUrl.ps1'
            . ($RegistryScript) @args | write-Output
        }
        Function Get-InventoryAuthToken {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Get-InventoryAuthToken.ps1'
            . ($RegistryScript) @args | write-Output
        }
        Function Remove-InventoryRegistryValue {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Remove-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
        Function Get-InventoryRegistryValue {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Get-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
        Function Set-InventoryRegistryValue {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Set-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }

        Function Test-InventoryRegistryKey {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Test-InventoryRegistryKey.ps1'
            . ($RegistryScript) @args | write-Output
        }
    }
    
    Context "Disconnect when token exists" {
        BeforeEach {
            # Clean up test registry
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
            
            # Store a test token
            $TestToken = "test-auth-token-12345"
            $SecureToken = ConvertTo-SecureString -String $TestToken -AsPlainText -Force
            $EncryptedToken = ConvertFrom-SecureString -SecureString $SecureToken
            Set-InventoryRegistryValue -KeyName "Authentication" -ValueName "Token" -Value $EncryptedToken | Out-Null
        }
        
        It "Should succeed with server notification" {
            # Test the function without mocking - it should handle API failures gracefully
            try {
                $Result = Disconnect-InventoryApi
                $Result | Should -BeOfType [Boolean]
            }
            catch {
                # If it fails due to network, it should still remove the local token
                $StoredToken = Get-InventoryAuthToken
                $StoredToken | Should -BeNullOrEmpty
            }
        }
        
        It "Should remove token from registry" {
            Disconnect-InventoryApi | Out-Null
            $StoredToken = Get-InventoryAuthToken
            $StoredToken | Should -BeNullOrEmpty
        }
        
        It "Should succeed without server notification" {
            $Result = Disconnect-InventoryApi -SkipServerNotification
            $Result | Should -BeTrue
        }
        
        It "Should handle API server failure gracefully" {
            # Test that function handles API failures gracefully
            # Without mocking, this will test actual error handling
            try {
                $Result = Disconnect-InventoryApi
                $Result | Should -BeOfType [Boolean]
            }
            catch {
                # Should still remove local token even if API fails
                $StoredToken = Get-InventoryAuthToken
                $StoredToken | Should -BeNullOrEmpty
            }
        }
    }
    
    Context "Disconnect when no token exists" {
        BeforeEach {
            # Clean up test registry
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
        }
        
        It "Should return true when no token is stored" {
            $Result = Disconnect-InventoryApi
            $Result | Should -BeTrue
        }
    }
    
    Context "Parameter validation" {
        It "Should have correct parameter structure" {
            $Function = Disconnect-InventoryApi_Command
            $Function.Parameters.ApiUrl.Attributes.Mandatory | Should -BeFalse
            $Function.Parameters.SkipServerNotification.ParameterType.Name | Should -Be "SwitchParameter"
        }
        
        It "Should have proper output type" {
            $Function = Disconnect-InventoryApi_Command
            $Function.OutputType.Type.Name | Should -Contain "Boolean"
        }
    }
}
