BeforeAll {
    # Load test helpers
    . (Join-Path $PSScriptRoot "..\TestHelpers.ps1")
    
    # Import functions needed for testing
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-ModuleFunctions -ModuleRoot $ModuleRoot -FunctionNames @(
        'Set-InventoryRegistryValue'
    )
    
    # Create a test registry path by appending '.test' to the module registry path
    $TestRegistryPath = $INVENTORY_CLI_REGISTRY_PATH + ".test"
}

Describe "Set-InventoryRegistryValue" {
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
    
    Context "When setting a value in an existing registry key" {
        BeforeAll {
            # Create test registry key
            New-Item -Path $TestRegistryPath -Force | Out-Null
            New-Item -Path (Join-Path $TestRegistryPath "TestKey") -Force | Out-Null
            
            # Mock the module constant for testing
            Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value $TestRegistryPath -Force
        }
        
        It "Should return true and set the value correctly" {
            $Result = Set-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue" -Value "TestData"
            $Result | Should -Be $true
            
            # Verify the value was set
            $ActualValue = Get-ItemProperty -Path (Join-Path $TestRegistryPath "TestKey") -Name "TestValue"
            $ActualValue.TestValue | Should -Be "TestData"
        }
    }
    
    Context "When setting a value in a non-existent registry key" {
        BeforeAll {
            # Ensure the parent path exists but the specific key doesn't
            New-Item -Path $TestRegistryPath -Force | Out-Null
            if (Test-Path (Join-Path $TestRegistryPath "NewKey")) {
                Remove-Item -Path (Join-Path $TestRegistryPath "NewKey") -Force
            }
            
            # Mock the module constant for testing
            Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value $TestRegistryPath -Force
        }
        
        It "Should create the key and set the value" {
            $Result = Set-InventoryRegistryValue -KeyName "NewKey" -ValueName "NewValue" -Value "NewData"
            $Result | Should -Be $true
            
            # Verify the key was created
            Test-Path (Join-Path $TestRegistryPath "NewKey") | Should -Be $true
            
            # Verify the value was set
            $ActualValue = Get-ItemProperty -Path (Join-Path $TestRegistryPath "NewKey") -Name "NewValue"
            $ActualValue.NewValue | Should -Be "NewData"
        }
    }
    
    Context "When parent registry path does not exist" {
        BeforeAll {
            # Mock the module constant to point to non-existent parent path
            Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value "HKCU:\SOFTWARE\nonexistent\parent\path" -Force
        }
        
        It "Should create the entire path and set the value" {
            $Result = Set-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue" -Value "TestData"
            $Result | Should -Be $true
            
            # Verify the entire path was created
            Test-Path "HKCU:\SOFTWARE\nonexistent\parent\path\TestKey" | Should -Be $true
            
            # Verify the value was set
            $ActualValue = Get-ItemProperty -Path "HKCU:\SOFTWARE\nonexistent\parent\path\TestKey" -Name "TestValue"
            $ActualValue.TestValue | Should -Be "TestData"
            
            # Clean up the created path
            Remove-Item -Path "HKCU:\SOFTWARE\nonexistent" -Recurse -Force
        }
    }
    
    Context "Different value types" {
        BeforeAll {
            # Create test registry key
            New-Item -Path $TestRegistryPath -Force | Out-Null
            New-Item -Path (Join-Path $TestRegistryPath "TypeTestKey") -Force | Out-Null
            
            # Mock the module constant for testing
            Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value $TestRegistryPath -Force
        }
        
        It "Should set String values correctly" {
            $Result = Set-InventoryRegistryValue -KeyName "TypeTestKey" -ValueName "StringValue" -Value "TestString" -ValueType "String"
            $Result | Should -Be $true
            
            $ActualValue = Get-ItemProperty -Path (Join-Path $TestRegistryPath "TypeTestKey") -Name "StringValue"
            $ActualValue.StringValue | Should -Be "TestString"
        }
        
        It "Should set DWord values correctly" {
            $Result = Set-InventoryRegistryValue -KeyName "TypeTestKey" -ValueName "DWordValue" -Value 42 -ValueType "DWord"
            $Result | Should -Be $true
            
            $ActualValue = Get-ItemProperty -Path (Join-Path $TestRegistryPath "TypeTestKey") -Name "DWordValue"
            $ActualValue.DWordValue | Should -Be 42
        }
        
        It "Should default to String type when not specified" {
            $Result = Set-InventoryRegistryValue -KeyName "TypeTestKey" -ValueName "DefaultTypeValue" -Value "DefaultString"
            $Result | Should -Be $true
            
            $ActualValue = Get-ItemProperty -Path (Join-Path $TestRegistryPath "TypeTestKey") -Name "DefaultTypeValue"
            $ActualValue.DefaultTypeValue | Should -Be "DefaultString"
        }
    }
    
    Context "Parameter validation" {
        It "Should require KeyName parameter" {
            # Use Get-Command to check parameter requirements
            $FunctionInfo = Get-Command Set-InventoryRegistryValue
            $KeyNameParam = $FunctionInfo.Parameters['KeyName']
            $KeyNameParam.Attributes.Mandatory | Should -Be $true
        }
        
        It "Should require ValueName parameter" {
            # Use Get-Command to check parameter requirements
            $FunctionInfo = Get-Command Set-InventoryRegistryValue
            $ValueNameParam = $FunctionInfo.Parameters['ValueName']
            $ValueNameParam.Attributes.Mandatory | Should -Be $true
        }
        
        It "Should require Value parameter" {
            # Use Get-Command to check parameter requirements
            $FunctionInfo = Get-Command Set-InventoryRegistryValue
            $ValueParam = $FunctionInfo.Parameters['Value']
            $ValueParam.Attributes.Mandatory | Should -Be $true
        }
        
        It "Should validate ValueType parameter" {
            { Set-InventoryRegistryValue -KeyName "Test" -ValueName "Test" -Value "Test" -ValueType "InvalidType" } | Should -Throw
        }
        
        It "Should accept valid ValueType parameters" {
            # Test each value type with appropriate test values
            $TestCases = @(
                @{ Type = 'String'; Value = 'TestString' }
                @{ Type = 'ExpandString'; Value = 'Test%TEMP%String' }
                @{ Type = 'Binary'; Value = [byte[]](1, 2, 3, 4) }
                @{ Type = 'DWord'; Value = 42 }
                @{ Type = 'MultiString'; Value = @('String1', 'String2') }
                @{ Type = 'QWord'; Value = [uint64]123456789 }
            )
            
            foreach ($TestCase in $TestCases) {
                { Set-InventoryRegistryValue -KeyName "Test" -ValueName "Test$($TestCase.Type)" -Value $TestCase.Value -ValueType $TestCase.Type } | Should -Not -Throw
            }
        }
    }
    
    Context "Update existing values" {
        BeforeAll {
            # Create test registry key with initial value
            New-Item -Path $TestRegistryPath -Force | Out-Null
            New-Item -Path (Join-Path $TestRegistryPath "UpdateTestKey") -Force | Out-Null
            Set-ItemProperty -Path (Join-Path $TestRegistryPath "UpdateTestKey") -Name "UpdateValue" -Value "InitialValue"
            
            # Mock the module constant for testing
            Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value $TestRegistryPath -Force
        }
        
        It "Should update existing values correctly" {
            # Verify initial value
            $InitialValue = Get-ItemProperty -Path (Join-Path $TestRegistryPath "UpdateTestKey") -Name "UpdateValue"
            $InitialValue.UpdateValue | Should -Be "InitialValue"
            
            # Update the value
            $Result = Set-InventoryRegistryValue -KeyName "UpdateTestKey" -ValueName "UpdateValue" -Value "UpdatedValue"
            $Result | Should -Be $true
            
            # Verify updated value
            $UpdatedValue = Get-ItemProperty -Path (Join-Path $TestRegistryPath "UpdateTestKey") -Name "UpdateValue"
            $UpdatedValue.UpdateValue | Should -Be "UpdatedValue"
        }
    }
}
