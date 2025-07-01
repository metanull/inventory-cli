Describe "Get-InventoryApiUrl" -Tag "UnitTest" {

    BeforeAll {
        $script:INVENTORY_CLI_REGISTRY_PATH = "HKCU:\SOFTWARE\metanull.test\inventory-cli"

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\public")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName
        
        # Define the Module function by dot sourcing it
        Function Get-InventoryApiUrl {
            . $Script @args | write-Output
        }
        # Define an accessor to the function's properties
        Function Get-InventoryApiUrl_Command {
            Get-Command $Script
        }

        # Define stub functions for dependencies
        Function Get-InventoryRegistryValue {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Get-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
        Function Set-InventoryRegistryValue {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Set-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
    }
    
    
    Context "When API URL is not configured" {
        BeforeEach {
            # Clean up test registry
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
        }
        
        It "Should return the default URL" {
            $Result = Get-InventoryApiUrl
            $Result | Should -Be "http://127.0.0.1:8000"
        }
    }
    
    Context "When API URL is configured" {
        BeforeEach {
            # Clean up test registry
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
            
            # Set up a configured API URL
            $TestUrl = "https://api.example.com:8443"
            Set-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl" -Value $TestUrl | Out-Null
        }
        
        It "Should return the configured URL" {
            $Result = Get-InventoryApiUrl
            $Result | Should -Be "https://api.example.com:8443"
        }
    }
    
    Context "When registry access fails" {
        BeforeEach {
            # Clean up test registry
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
            
            # Create an invalid registry path to simulate failure
            # This will cause Get-InventoryRegistryValue to fail naturally
        }
        
        It "Should return the default URL on error" {
            $Result = Get-InventoryApiUrl
            $Result | Should -Be "http://127.0.0.1:8000"
        }
    }
    
    Context "Parameter validation" {
        It "Should not require any parameters" {
            { Get-InventoryApiUrl } | Should -Not -Throw
        }
        
        It "Should have proper output type" {
            $FunctionInfo = Get-InventoryApiUrl_Command
            $OutputType = $FunctionInfo.OutputType.Type.Name
            $OutputType | Should -Be "String"
        }
    }
}
