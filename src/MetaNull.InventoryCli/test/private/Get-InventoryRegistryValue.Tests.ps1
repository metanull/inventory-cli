Describe "Get-InventoryRegistryValue" -Tag "UnitTest" {

    BeforeAll {
        $script:INVENTORY_CLI_REGISTRY_PATH = "HKCU:\SOFTWARE\metanull.test\inventory-cli"

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\private")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName
        
        # Define the Module function by dot sourcing it
        Function Get-InventoryRegistryValue {
            . $Script @args | write-Output
        }
        # Define an accessor to the function's properties
        Function Get-InventoryRegistryValue_Command {
            Get-Command $Script
        }


        Function Set-InventoryRegistryValue {
            $RegistryScript = Join-Path $ScriptDirectory 'Set-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
    }
    
    Context "When registry key and value exist" {
        BeforeAll {
            New-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Force | Out-Null
            New-Item -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "TestKey") -Force | Out-Null
            Set-ItemProperty -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "TestKey") -Name "TestValue" -Value "TestData"
        }
        
        It "Should return the correct value" {
            Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "TestValue" | Should -Be "TestData"
        }
    }
    
    Context "When registry key exists but value does not" {
        BeforeAll {
            New-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Force | Out-Null
            New-Item -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "TestKey") -Force | Out-Null
        }
        
        It "Should return null" {
            Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "NonExistentValue" | Should -Be $null
        }
    }
    
    Context "When registry key does not exist" {
        BeforeAll {
        }
        
        It "Should return null" {
            Get-InventoryRegistryValue -KeyName "NonExistentKey" -ValueName "TestValue" | Should -Be $null
        }
    }
    
    Context "When parent registry path does not exist" {
        BeforeAll {
        }
        
        It "Should return null" {
            Get-InventoryRegistryValue -KeyName "AnyKey" -ValueName "AnyValue" | Should -Be $null
        }
    }
    
    Context "Parameter validation" {
        It "Should require KeyName parameter" {
            # Use Get-Command to check parameter requirements
            $FunctionInfo = Get-InventoryRegistryValue_Command
            $KeyNameParam = $FunctionInfo.Parameters['KeyName']
            $KeyNameParam.Attributes.Mandatory | Should -Be $true
        }
        
        It "Should require ValueName parameter" {
            # Use Get-Command to check parameter requirements
            $FunctionInfo = Get-InventoryRegistryValue_Command
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
            New-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Force | Out-Null
            New-Item -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "TestKey") -Force | Out-Null
            
            # Set different types of values
            Set-ItemProperty -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "TestKey") -Name "StringValue" -Value "TestString" -Type String
            Set-ItemProperty -Path (Join-Path $script:INVENTORY_CLI_REGISTRY_PATH "TestKey") -Name "DWordValue" -Value 42 -Type DWord
        }
        
        It "Should retrieve string values correctly" {
            Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "StringValue" | Should -Be "TestString"
        }
        
        It "Should retrieve DWord values correctly" {
            Get-InventoryRegistryValue -KeyName "TestKey" -ValueName "DWordValue" | Should -Be 42
        }
    }
}
