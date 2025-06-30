Describe "Connect-InventoryApi" {
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
            'Connect-InventoryApi',
            'Get-InventoryApiUrl',
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
        
        # Create test credentials
        $TestPassword = ConvertTo-SecureString "testpassword" -AsPlainText -Force
        $TestCredential = New-Object System.Management.Automation.PSCredential("testuser", $TestPassword)
    }
    
    AfterAll {
        # Clean up test registry keys
        if (Test-Path $TestRegistryPath) {
            Remove-Item -Path $TestRegistryPath -Recurse -Force
        }
    }
    
    Context "Successful authentication" {
        BeforeAll {
            # Mock Invoke-RestMethod to simulate successful authentication
            Mock Invoke-RestMethod {
                return @{ token = "mock-auth-token-12345" }
            }
        }
        
        It "Should return true on successful authentication" {
            $Result = Connect-InventoryApi -Credential $TestCredential
            $Result | Should -BeTrue
        }
        
        It "Should store the token in registry" {
            Connect-InventoryApi -Credential $TestCredential | Out-Null
            $StoredToken = Get-InventoryRegistryValue -KeyName "Authentication" -ValueName "Token"
            $StoredToken | Should -Not -BeNullOrEmpty
        }
        
        It "Should use custom API URL when provided" {
            $CustomUrl = "https://custom.api.com"
            Connect-InventoryApi -Credential $TestCredential -ApiUrl $CustomUrl | Out-Null
            
            # Verify the correct endpoint was called
            Assert-MockCalled Invoke-RestMethod -ParameterFilter { 
                $Uri -eq "$CustomUrl/auth/login" 
            }
        }
        
        It "Should use configured API URL when not provided" {
            # Set a configured API URL
            Set-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl" -Value "https://configured.api.com" | Out-Null
            
            Connect-InventoryApi -Credential $TestCredential | Out-Null
            
            # Verify the configured endpoint was called
            Assert-MockCalled Invoke-RestMethod -ParameterFilter { 
                $Uri -eq "https://configured.api.com/auth/login" 
            }
        }
    }
    
    Context "Failed authentication" {
        BeforeAll {
            # Clear any existing token first
            if (Test-Path "$TestRegistryPath\Authentication") {
                Remove-Item -Path "$TestRegistryPath\Authentication" -Recurse -Force
            }
            
            # Mock Invoke-RestMethod to simulate authentication failure
            Mock Invoke-RestMethod {
                throw "Unauthorized"
            } -ModuleName $null
        }
        
        It "Should return false on authentication failure" {
            $Result = Connect-InventoryApi -Credential $TestCredential
            $Result | Should -BeFalse
        }
        
        It "Should not store token on authentication failure" {
            Connect-InventoryApi -Credential $TestCredential | Out-Null
            $StoredToken = Get-InventoryRegistryValue -KeyName "Authentication" -ValueName "Token"
            $StoredToken | Should -BeNullOrEmpty
        }
    }
    
    Context "Invalid API response" {
        BeforeAll {
            # Mock Invoke-RestMethod to return response without token
            Mock Invoke-RestMethod {
                return @{ message = "Login successful but no token" }
            }
        }
        
        It "Should return false when response has no token" {
            $Result = Connect-InventoryApi -Credential $TestCredential
            $Result | Should -BeFalse
        }
    }
    
    Context "Registry storage failure" {
        BeforeAll {
            # Mock successful API response but failed registry storage
            Mock Invoke-RestMethod {
                return @{ token = "mock-auth-token-12345" }
            }
            Mock Set-InventoryRegistryValue { return $false }
        }
        
        It "Should return false when token storage fails" {
            $Result = Connect-InventoryApi -Credential $TestCredential
            $Result | Should -BeFalse
        }
    }
    
    Context "Parameter validation" {
        It "Should require Credential parameter" {
            $Function = Get-Command Connect-InventoryApi
            $Function.Parameters.Credential.Attributes.Mandatory | Should -BeTrue
        }
        
        It "Should accept PSCredential for Credential parameter" {
            $Function = Get-Command Connect-InventoryApi
            $Function.Parameters.Credential.ParameterType.Name | Should -Be "PSCredential"
        }
        
        It "Should have optional ApiUrl parameter" {
            $Function = Get-Command Connect-InventoryApi
            $Function.Parameters.ApiUrl.Attributes.Mandatory | Should -BeFalse
        }
        
        It "Should have proper output type" {
            $Function = Get-Command Connect-InventoryApi
            $Function.OutputType.Type.Name | Should -Contain "Boolean"
        }
    }
}
