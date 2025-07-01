Describe "Remove-InventoryRegistryValue" -Tag "UnitTest" {

    BeforeAll {
        $script:INVENTORY_CLI_REGISTRY_PATH = "HKCU:\SOFTWARE\metanull.test\inventory-cli"

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\private")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName
        
        # Define the Module function by dot sourcing it
        Function Remove-InventoryRegistryValue {
            . $Script @args | write-Output
        }
        # Define an accessor to the function's properties
        Function Remove-InventoryRegistryValue_Command {
            Get-Command $Script
        }

        Function Test-InventoryRegistryKey {
            $RegistryScript = Join-Path $ScriptDirectory 'Test-InventoryRegistryKey.ps1'
            . ($RegistryScript) @args | write-Output
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
    
    Context "Remove existing registry value" {
        BeforeEach {
            # Create test registry key and value
            New-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Force | Out-Null
            New-Item -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "TestKey") -Force | Out-Null
            Set-ItemProperty -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "TestKey") -Name "TestValue" -Value "TestData"
        }
        
        It "Should return true when value is removed successfully" {
            $Result = Remove-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue"
            $Result | Should -Be $true
        }
        
        It "Should actually remove the value from registry" {
            Remove-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue" | Out-Null
            $RemainingValue = Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue"
            $RemainingValue | Should -BeNullOrEmpty
        }
    }
    
    Context "Remove non-existent registry value" {
        It "Should return true when value does not exist" {
            $Result = Remove-InventoryRegistryValue -KeyName "NonExistentKey" -ValueName "NonExistentValue"
            $Result | Should -Be $true
        }
        
        It "Should return true when key exists but value does not" {
            # Create key without the target value
            New-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Force | Out-Null
            New-Item -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "ExistingKey") -Force | Out-Null
            Set-ItemProperty -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "ExistingKey") -Name "OtherValue" -Value "Data"
            
            $Result = Remove-InventoryRegistryValue -KeyName "ExistingKey" -ValueName "NonExistentValue"
            $Result | Should -Be $true
        }
    }
    
    Context "Parameter validation" {
        It "Should require KeyName parameter" {
            $Function = Remove-InventoryRegistryValue_Command
            $Function.Parameters.KeyName.Attributes.Mandatory | Should -Be $true
        }
        
        It "Should require ValueName parameter" {
            $Function = Remove-InventoryRegistryValue_Command
            $Function.Parameters.ValueName.Attributes.Mandatory | Should -Be $true
        }
        
        It "Should have proper output type" {
            $Function = Remove-InventoryRegistryValue_Command
            $Function.OutputType.Type.Name | Should -Contain "Boolean"
        }
    }
}
