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

    AfterEach {
        # Clean up test registry
        if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
            Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
        }
    }
    
    
    Context "When API URL is not configured" {
        
        It "Should return the default URL" {
            $Result = Get-InventoryApiUrl
            $Result | Should -Be "http://127.0.0.1:8000"
        }
    }
    
    Context "When API URL is configured" {
        BeforeEach {
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
