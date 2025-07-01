Describe "Get-InventoryAuthToken" -Tag "FeatureTest" {

    BeforeAll {
        $script:INVENTORY_CLI_REGISTRY_PATH = "HKCU:\SOFTWARE\metanull.test\inventory-cli"

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\private")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName
        
        # Define the Module function by dot sourcing it
        Function Get-InventoryAuthToken {
            . $Script @args | write-Output
        }
        # Define an accessor to the function's properties
        Function Get-InventoryAuthToken_Command {
            Get-Command $Script
        }

        Function Get-InventoryRegistryValue {
            $RegistryScript = Join-Path $ScriptDirectory 'Get-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
        Function Set-InventoryRegistryValue {
            $RegistryScript = Join-Path $ScriptDirectory 'Set-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
    }
    
    Context "When no token is stored" {
        It "Should return null" {
            $Result = Get-InventoryAuthToken
            $Result | Should -BeNullOrEmpty
        }
    }
    
    Context "When a valid token is stored" {
        BeforeAll {
            # Store a test token
            $TestToken = "test-auth-token-12345"
            $SecureToken = ConvertTo-SecureString -String $TestToken -AsPlainText -Force
            $EncryptedToken = ConvertFrom-SecureString -SecureString $SecureToken
            Set-InventoryRegistryValue -KeyName "Authentication" -ValueName "Token" -Value $EncryptedToken | Out-Null
        }
        
        It "Should return the decrypted token" {
            $Result = Get-InventoryAuthToken
            $Result | Should -Be "test-auth-token-12345"
        }
    }
    
    Context "When an invalid token is stored" {
        BeforeAll {
            # Store an invalid encrypted token
            Set-InventoryRegistryValue -KeyName "Authentication" -ValueName "Token" -Value "invalid-encrypted-data" | Out-Null
        }
        
        It "Should return null for invalid token data" {
            $Result = Get-InventoryAuthToken
            $Result | Should -BeNullOrEmpty
        }
    }
    
    Context "When registry access fails" {
        BeforeAll {
            # Mock Get-InventoryRegistryValue to simulate failure
            Mock Get-InventoryRegistryValue {
                throw "Registry access failed" 
            }
        }
        
        It "Should return null on registry error" {
            { Get-InventoryAuthToken } | Should -Not -Throw
            $Result | Should -BeNullOrEmpty
        }
    }
    
    Context "Parameter validation" {
        It "Should not require any mandatory parameters" {
            $Function = Get-Command Get-InventoryAuthToken
            $MandatoryParams = $Function.Parameters.Values | Where-Object { $_.Attributes.Mandatory -eq $true }
            $MandatoryParams | Should -BeNullOrEmpty
        }
        
        It "Should have proper output type" {
            $Function = Get-InventoryAuthToken_Command
            $Function.OutputType.Type.Name | Should -Contain "String"
        }
    }
}
