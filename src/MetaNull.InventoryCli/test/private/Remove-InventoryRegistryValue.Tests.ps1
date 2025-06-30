Describe "Remove-InventoryRegistryValue" {
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
            'Remove-InventoryRegistryValue',
            'Test-InventoryRegistryKey',
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
        Mock Test-InventoryRegistryKey {
            param($KeyName)
            $TestPath = "$TestRegistryPath\$KeyName"
            return (Test-Path $TestPath)
        }
        
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
        
        # Override registry operations to use test path instead of mocking the constant
        Mock Get-ItemProperty {
            param($Path, $Name, $ErrorAction)
            # Redirect to test path
            $TestPath = $Path -replace [regex]::Escape($INVENTORY_CLI_REGISTRY_PATH), $TestRegistryPath
            if (Test-Path $TestPath) {
                try {
                    $Item = Microsoft.PowerShell.Management\Get-ItemProperty -Path $TestPath -Name $Name -ErrorAction $ErrorAction
                    return $Item
                } catch {
                    if ($ErrorAction -eq 'Stop') { throw }
                    return $null
                }
            } else {
                if ($ErrorAction -eq 'Stop') { throw "Registry path not found" }
                return $null
            }
        }
        
        Mock Remove-ItemProperty {
            param($Path, $Name, $ErrorAction)
            # Redirect to test path
            $TestPath = $Path -replace [regex]::Escape($INVENTORY_CLI_REGISTRY_PATH), $TestRegistryPath
            if (Test-Path $TestPath) {
                try {
                    Microsoft.PowerShell.Management\Remove-ItemProperty -Path $TestPath -Name $Name -ErrorAction $ErrorAction
                } catch {
                    if ($ErrorAction -eq 'Stop') { throw }
                }
            }
        }
    }
    
    AfterAll {
        # Clean up test registry keys
        if (Test-Path $TestRegistryPath) {
            Remove-Item -Path $TestRegistryPath -Recurse -Force
        }
    }
    
    Context "Remove existing registry value" {
        BeforeEach {
            # Create test registry key and value
            $TestKeyName = "TestKey"
            $TestValueName = "TestValue"
            $TestValue = "TestData"
            
            Set-InventoryRegistryValue -KeyName $TestKeyName -ValueName $TestValueName -Value $TestValue | Out-Null
        }
        
        It "Should return true when value is removed successfully" {
            $Result = Remove-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue"
            $Result | Should -BeTrue
        }
        
        It "Should actually remove the value from registry" {
            Remove-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue" | Out-Null
            $RemainingValue = Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue"
            $RemainingValue | Should -BeNullOrEmpty
        }
        
        It "Should handle verbose output properly" {
            $VerboseOutput = Remove-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue" -Verbose 4>&1
            $VerboseOutput | Should -Not -BeNullOrEmpty
            # Check that some verbose output was generated (could be multiple lines)
            $VerboseOutput -join " " | Should -Match "Registry|TestKey|TestValue"
        }
    }
    
    Context "Remove non-existent registry value" {
        It "Should return true when value does not exist" {
            $Result = Remove-InventoryRegistryValue -KeyName "NonExistentKey" -ValueName "NonExistentValue"
            $Result | Should -BeTrue
        }
        
        It "Should return true when key exists but value does not" {
            # Create key without the target value
            Set-InventoryRegistryValue -KeyName "ExistingKey" -ValueName "OtherValue" -Value "Data" | Out-Null
            
            $Result = Remove-InventoryRegistryValue -KeyName "ExistingKey" -ValueName "NonExistentValue"
            $Result | Should -BeTrue
        }
    }
    
    Context "Error handling" {
        It "Should return false when registry operation fails" {
            # Mock Get-ItemProperty to succeed (value exists)
            Mock Get-ItemProperty { return @{ TestValue = "TestData" } } -ParameterFilter { $Name -eq "TestValue" }
            
            # Mock Remove-ItemProperty to fail
            Mock Remove-ItemProperty { throw "Registry access denied" } -ParameterFilter { $Name -eq "TestValue" }
            
            # Mock Test-InventoryRegistryKey to return true (key exists)
            Mock Test-InventoryRegistryKey { return $true } -ParameterFilter { $KeyName -eq "TestKey" }
            
            $Result = Remove-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue"
            $Result | Should -BeFalse
        }
    }
    
    Context "Parameter validation" {
        It "Should require KeyName parameter" {
            $Function = Get-Command Remove-InventoryRegistryValue
            $Function.Parameters.KeyName.Attributes.Mandatory | Should -BeTrue
        }
        
        It "Should require ValueName parameter" {
            $Function = Get-Command Remove-InventoryRegistryValue
            $Function.Parameters.ValueName.Attributes.Mandatory | Should -BeTrue
        }
        
        It "Should have proper output type" {
            $Function = Get-Command Remove-InventoryRegistryValue
            $Function.OutputType.Type.Name | Should -Contain "Boolean"
        }
        
        It "Should support CmdletBinding" {
            $Function = Get-Command Remove-InventoryRegistryValue
            $Function.CmdletBinding | Should -BeTrue
        }
    }
}
