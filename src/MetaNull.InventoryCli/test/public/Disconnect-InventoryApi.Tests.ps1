Describe "Disconnect-InventoryApi" {
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
            'Disconnect-InventoryApi',
            'Get-InventoryApiUrl',
            'Get-InventoryAuthToken',
            'Get-InventoryRegistryValue',
            'Set-InventoryRegistryValue',
            'Remove-InventoryRegistryValue',
            'Test-InventoryRegistryKey'
        )
        
        # Create a test registry path by appending '.test' to the module registry path
        $TestRegistryPath = $INVENTORY_CLI_REGISTRY_PATH + ".test"
    }
    
    AfterAll {
        # Clean up test registry keys
        if (Test-Path $TestRegistryPath) {
            Remove-Item -Path $TestRegistryPath -Recurse -Force
        }
    }
    
    Context "Basic functionality tests" {
        BeforeEach {
            # Clean up any existing test keys
            if (Test-Path $TestRegistryPath) {
                Remove-Item -Path $TestRegistryPath -Recurse -Force
            }
        }
        
        It "Should return true when no token is stored" {
            $Result = Disconnect-InventoryApi -SkipServerNotification
            $Result | Should -BeTrue
        }
        
        It "Should have correct parameter structure" {
            $Function = Get-Command Disconnect-InventoryApi
            $Function.Parameters.ApiUrl.Attributes.Mandatory | Should -BeFalse
            $Function.Parameters.SkipServerNotification.ParameterType.Name | Should -Be "SwitchParameter"
        }
        
        It "Should have proper output type" {
            $Function = Get-Command Disconnect-InventoryApi
            $Function.OutputType.Type.Name | Should -Contain "Boolean"
        }
    }
    
    Context "API mocking tests" {
        BeforeEach {
            # Clean up any existing test keys
            if (Test-Path $TestRegistryPath) {
                Remove-Item -Path $TestRegistryPath -Recurse -Force
            }
            
            # Store a test token for logout tests
            $TestToken = "test-auth-token-12345"
            $SecureToken = ConvertTo-SecureString -String $TestToken -AsPlainText -Force
            $EncryptedToken = ConvertFrom-SecureString -SecureString $SecureToken
            
            # Create test registry key and store token
            $TestAuthPath = "$TestRegistryPath\Authentication"
            if (-not (Test-Path $TestAuthPath)) {
                New-Item -Path $TestAuthPath -Force | Out-Null
            }
            Set-ItemProperty -Path $TestAuthPath -Name "Token" -Value $EncryptedToken
            
            # Mock registry functions to use test path
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
            
            Mock Test-InventoryRegistryKey {
                param($KeyName)
                $TestPath = "$TestRegistryPath\$KeyName"
                return (Test-Path $TestPath)
            }
            
            Mock Remove-InventoryRegistryValue {
                param($KeyName, $ValueName)
                $TestPath = "$TestRegistryPath\$KeyName"
                if (Test-Path $TestPath) {
                    try {
                        Remove-ItemProperty -Path $TestPath -Name $ValueName -ErrorAction Stop
                        return $true
                    } catch {
                        return $false
                    }
                }
                return $true
            }
        }
        
        It "Should succeed with server notification" {
            # Mock successful API response
            Mock Invoke-RestMethod { return @{ message = "Logout successful" } }
            
            $Result = Disconnect-InventoryApi
            $Result | Should -BeTrue
        }
        
        It "Should succeed without server notification" {
            $Result = Disconnect-InventoryApi -SkipServerNotification
            $Result | Should -BeTrue
        }
        
        It "Should handle API server failure gracefully" {
            # Mock API failure
            Mock Invoke-RestMethod { throw "Server error" }
            
            $Result = Disconnect-InventoryApi
            $Result | Should -BeTrue  # Should still succeed since it removes local token
        }
    }
}
