Describe "Remove-InventoryApiUrl" -Tag "UnitTest" {

    BeforeAll {
        $script:INVENTORY_CLI_REGISTRY_PATH = "HKCU:\SOFTWARE\metanull.test\inventory-cli"

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\public")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName
        
        # Define the Module function by dot sourcing it
        Function Remove-InventoryApiUrl {
            . $Script @args | write-Output
        }
        # Define an accessor to the function's properties
        Function Remove-InventoryApiUrl_Command {
            Get-Command $Script
        }

        # Define stub functions for dependencies
        Function Remove-InventoryRegistryValue {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Remove-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
        Function Get-InventoryRegistryValue {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Get-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
        Function Set-InventoryRegistryValue {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Set-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
    }

    AfterEach {
        # Clean up test registry
        if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
            Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
        }
    }
    
    
    Context "Removing existing API URL" {
        BeforeEach {
            # Clean up test registry
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
        }

        AfterEach {
            # Clean up after each test
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
        }
        
        It "Should remove the configured URL" {
            $Result = Remove-InventoryApiUrl
            $Result | Should -Be $true
            
            # Verify the value was removed
            $StoredUrl = Get-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl"
            $StoredUrl | Should -Be $null
        }
    }
    
    Context "Removing non-existent API URL" {

        It "Should return true when URL is not configured" {
            $Result = Remove-InventoryApiUrl
            $Result | Should -Be $true
        }
    }
    
    Context "ShouldProcess support" {
        BeforeEach {
            # Set up a configured API URL
            Set-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl" -Value "https://test.example.com" | Out-Null
        }
        AfterEach {
            # Clean up after each test
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
        }
        
        It "Should support WhatIf parameter" {
            $FunctionInfo = Remove-InventoryApiUrl_Command
            $FunctionInfo.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }
        
        It "Should support Confirm parameter" {
            $FunctionInfo = Remove-InventoryApiUrl_Command
            $FunctionInfo.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
        
        It "Should not remove URL when WhatIf is used" {
            Remove-InventoryApiUrl -WhatIf
            
            # Verify the value still exists
            $StoredUrl = Get-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl"
            $StoredUrl | Should -Be "https://test.example.com"
        }
    }
    
    Context "Parameter validation" {
        It "Should not require any parameters" {
            { Remove-InventoryApiUrl } | Should -Not -Throw
        }
        
        It "Should have proper output type" {
            $FunctionInfo = Remove-InventoryApiUrl_Command
            $OutputType = $FunctionInfo.OutputType.Type.Name
            $OutputType | Should -Be "Boolean"
        }
        
        It "Should support SupportsShouldProcess" {
            $FunctionInfo = Remove-InventoryApiUrl_Command
            $SupportsShouldProcess = $FunctionInfo.Parameters.ContainsKey('WhatIf') -and $FunctionInfo.Parameters.ContainsKey('Confirm')
            $SupportsShouldProcess | Should -Be $true
        }
    }
}
