Describe "Test-InventoryRegistryKey" -Tag "UnitTest" {

    BeforeAll {
        $script:INVENTORY_CLI_REGISTRY_PATH = "HKCU:\SOFTWARE\metanull.test\inventory-cli"

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\private")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName
        
        # Define the Module function by dot sourcing it
        Function Test-InventoryRegistryKey {
            . $Script @args | write-Output
        }
        # Define an accessor to the function's properties
        Function Test-InventoryRegistryKey_Command {
            Get-Command $Script
        }
    }
    
    Context "When registry key exists" {
        BeforeAll {
            # Create test registry key
            New-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Force | Out-Null
            New-Item -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "ExistingKey") -Force | Out-Null
        }
        
        It "Should return true for existing key" {
            $Result = Test-InventoryRegistryKey -KeyName "ExistingKey"
            $Result | Should -Be $true
        }
    }
    
    Context "When registry key does not exist" {
        It "Should return false for non-existing key" {
            $Result = Test-InventoryRegistryKey -KeyName "NonExistentKey"
            $Result | Should -Be $false
        }
    }
    
    Context "When parent registry path does not exist" {
        It "Should return false when parent path does not exist" {
            $Result = Test-InventoryRegistryKey -KeyName "AnyKey"
            $Result | Should -Be $false
        }
    }
    
    Context "Parameter validation" {
        It "Should require KeyName parameter" {
            $Function = Test-InventoryRegistryKey_Command
            $Function.Parameters.KeyName.Attributes.Mandatory | Should -Be $true
        }
        
        It "Should accept string parameter" {
            { Test-InventoryRegistryKey -KeyName "TestKey" } | Should -Not -Throw
        }
        
        It "Should have proper output type" {
            $Function = Test-InventoryRegistryKey_Command
            $Function.OutputType.Type.Name | Should -Contain "Boolean"
        }
    }
    
    Context "Edge cases" {
        BeforeAll {
            # Create test registry structure
            New-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Force | Out-Null
            New-Item -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "EmptyKey") -Force | Out-Null
        }
        
        It "Should return true for empty registry key" {
            $Result = Test-InventoryRegistryKey -KeyName "EmptyKey"
            $Result | Should -Be $true
        }
        
        It "Should handle special characters in key names" {
            # Create key with special characters (if valid)
            $SpecialKeyName = "Key-With_Special.Characters"
            New-Item -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH $SpecialKeyName) -Force | Out-Null
            
            $Result = Test-InventoryRegistryKey -KeyName $SpecialKeyName
            $Result | Should -Be $true
        }
    }
}
