BeforeAll {
    # Load test helpers
    . (Join-Path $PSScriptRoot "..\TestHelpers.ps1")
    
    # Import functions needed for testing
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-ModuleFunctions -ModuleRoot $ModuleRoot -FunctionNames @(
        'Get-InventoryRegistryValue'
    )
    
    # Create a test registry path by appending '.test' to the module registry path
    $TestRegistryPath = $INVENTORY_CLI_REGISTRY_PATH + ".test"
}

Describe "Get-InventoryRegistryValue" {
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
        # Clean up any existing test keys
        if (Test-Path $TestRegistryPath) {
            Remove-Item -Path $TestRegistryPath -Recurse -Force
        }
    }
    
    AfterAll {
        # Clean up test registry keys
        if (Test-Path $TestRegistryPath) {
            Remove-Item -Path $TestRegistryPath -Recurse -Force
        }
    }
    
    Context "When registry key and value exist" {
        BeforeAll {
            # Create test registry key and value
            New-Item -Path $TestRegistryPath -Force | Out-Null
            New-Item -Path (Join-Path $TestRegistryPath "TestKey") -Force | Out-Null
            Set-ItemProperty -Path (Join-Path $TestRegistryPath "TestKey") -Name "TestValue" -Value "TestData"
            
            # Mock the module constant for testing
            Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value $TestRegistryPath -Force
        }
        
        It "Should return the correct value" {
            Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue" | Should -Be "TestData"
        }
    }
    
    Context "When registry key exists but value does not" {
        BeforeAll {
            # Create test registry key without the value
            New-Item -Path $TestRegistryPath -Force | Out-Null
            New-Item -Path (Join-Path $TestRegistryPath "TestKey") -Force | Out-Null
            
            # Mock the module constant for testing
            Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value $TestRegistryPath -Force
        }
        
        It "Should return null" {
            Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "NonExistentValue" | Should -Be $null
        }
    }
    
    Context "When registry key does not exist" {
        BeforeAll {
            # Mock the module constant for testing
            Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value $TestRegistryPath -Force
        }
        
        It "Should return null" {
            Get-InventoryRegistryValue -KeyName "NonExistentKey" -ValueName "TestValue" | Should -Be $null
        }
    }
    
    Context "When parent registry path does not exist" {
        BeforeAll {
            # Mock the module constant to point to non-existent path
            Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value "HKCU:\SOFTWARE\nonexistent\path" -Force
        }
        
        It "Should return null" {
            Get-InventoryRegistryValue -KeyName "AnyKey" -ValueName "AnyValue" | Should -Be $null
        }
    }
    
    Context "Parameter validation" {
        It "Should require KeyName parameter" {
            # Use Get-Command to check parameter requirements
            $FunctionInfo = Get-Command Get-InventoryRegistryValue
            $KeyNameParam = $FunctionInfo.Parameters['KeyName']
            $KeyNameParam.Attributes.Mandatory | Should -Be $true
        }
        
        It "Should require ValueName parameter" {
            # Use Get-Command to check parameter requirements
            $FunctionInfo = Get-Command Get-InventoryRegistryValue
            $ValueNameParam = $FunctionInfo.Parameters['ValueName']
            $ValueNameParam.Attributes.Mandatory | Should -Be $true
        }
        
        It "Should accept string parameters" {
            { Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue" } | Should -Not -Throw
        }
    }
    
    Context "Different value types" {
        BeforeAll {
            # Create test registry key
            New-Item -Path $TestRegistryPath -Force | Out-Null
            New-Item -Path (Join-Path $TestRegistryPath "TestKey") -Force | Out-Null
            
            # Set different types of values
            Set-ItemProperty -Path (Join-Path $TestRegistryPath "TestKey") -Name "StringValue" -Value "TestString" -Type String
            Set-ItemProperty -Path (Join-Path $TestRegistryPath "TestKey") -Name "DWordValue" -Value 42 -Type DWord
            
            # Mock the module constant for testing
            Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value $TestRegistryPath -Force
        }
        
        It "Should retrieve string values correctly" {
            Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "StringValue" | Should -Be "TestString"
        }
        
        It "Should retrieve DWord values correctly" {
            Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "DWordValue" | Should -Be 42
        }
    }
}
