Describe "Get-InventoryAuthToken" {
    Context "Test Environment Validation" {
        It "Should be running from the correct working directory" {
            $CurrentPath = Get-Location
            $ExpectedPath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
            $ExpectedPath = Resolve-Path $ExpectedPath
            
            if ($CurrentPath.Path -ne $ExpectedPath.Path) {
                Write-Warning "Tests should be run from the module root directory: $ExpectedPath"
                Write-Warning "Current working directory: $CurrentPath"
                Write-Warning "Please navigate to the module directory before running tests."
            }
            
            # This test will pass but warn if not in the right directory
            $CurrentPath.Path | Should -Be $ExpectedPath.Path -Because "Tests must be run from the module root directory for proper path resolution"
        }
    }
    
    BeforeAll {
        # Load test helpers
        . (Join-Path $PSScriptRoot "..\TestHelpers.ps1")
        
        # Import functions needed for testing
        $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        Import-ModuleFunctions -ModuleRoot $ModuleRoot -FunctionNames @(
            'Get-InventoryAuthToken',
            'Get-InventoryRegistryValue',
            'Set-InventoryRegistryValue'
        )
        
        # Create a test registry path by appending '.test' to the module registry path
        $TestRegistryPath = $INVENTORY_CLI_REGISTRY_PATH + ".test"
        
        # Clean up any existing test keys
        if (Test-Path $TestRegistryPath) {
            Remove-Item -Path $TestRegistryPath -Recurse -Force
        }
        
        # Mock the registry functions to use test path
        Mock Get-InventoryRegistryValue {
            param($KeyName, $ValueName)
            $TestPath = "$TestRegistryPath\$KeyName"
            if (Test-Path $TestPath) {
                try {
                    $Item = Get-ItemProperty -Path $TestPath -Name $ValueName -ErrorAction Stop
                    return $Item.$ValueName
                } catch {
                    return $null
                }
            }
            return $null
        }
        
        Mock Set-InventoryRegistryValue {
            param($KeyName, $ValueName, $Value, $ValueType = 'String')
            $TestPath = "$TestRegistryPath\$KeyName"
            if (-not (Test-Path $TestPath)) {
                New-Item -Path $TestPath -Force | Out-Null
            }
            Set-ItemProperty -Path $TestPath -Name $ValueName -Value $Value -Type $ValueType
            return $true
        }
    }
    
    AfterAll {
        # Clean up test registry keys
        if (Test-Path $TestRegistryPath) {
            Remove-Item -Path $TestRegistryPath -Recurse -Force
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
            Mock Get-InventoryRegistryValue { throw "Registry access failed" }
        }
        
        It "Should return null on registry error" {
            $Result = Get-InventoryAuthToken
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
            $Function = Get-Command Get-InventoryAuthToken
            $Function.OutputType.Type.Name | Should -Contain "String"
        }
    }
}
