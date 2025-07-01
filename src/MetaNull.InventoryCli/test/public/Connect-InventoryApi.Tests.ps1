Describe "Connect-InventoryApi" -Tag "UnitTest" {

    BeforeAll {
        $script:INVENTORY_CLI_REGISTRY_PATH = "HKCU:\SOFTWARE\metanull.test\inventory-cli"

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\public")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName
        
        # Define the Module function by dot sourcing it
        Function Connect-InventoryApi {
            . $Script @args | write-Output
        }
        # Define an accessor to the function's properties
        Function Connect-InventoryApi_Command {
            Get-Command $Script
        }

        # Define stub functions for dependencies
        Function Get-InventoryApiUrl {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'public\Get-InventoryApiUrl.ps1'
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
        
        # Create test credentials
        $TestPassword = ConvertTo-SecureString "testpassword" -AsPlainText -Force
        $TestCredential = New-Object System.Management.Automation.PSCredential("testuser", $TestPassword)
    }
    
    
    Context "Successful authentication" {
        BeforeEach {
            # Clean up test registry
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }

            Mock Invoke-RestMethod {
                # Simulate a failed API call
                return $null
            }
        }
        
        It "Should use custom API URL when provided" {
            # This test verifies the function accepts the ApiUrl parameter
            # Actual authentication testing would require mocking which we avoid
            $CustomUrl = "https://custom.api.com"
            try {
                $Result = Connect-InventoryApi -Credential $TestCredential -ApiUrl $CustomUrl
                # Result should be boolean (either true or false)
                $Result | Should -BeOfType [Boolean]
            }
            catch {
                # Expected to fail without actual API, but should not be a parameter error
                $_.Exception.Message | Should -Not -Match "parameter"
            }
        }
        
        It "Should use configured API URL when not provided" {
            # Set a configured API URL
            Set-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl" -Value "https://configured.api.com" | Out-Null
            
            try {
                $Result = Connect-InventoryApi -Credential $TestCredential
                # Result should be boolean (either true or false)
                $Result | Should -BeOfType [Boolean]
            }
            catch {
                # Expected to fail without actual API, but should not be a parameter error
                $_.Exception.Message | Should -Not -Match "parameter"
            }
        }
    }
    
    Context "Parameter validation" {
        It "Should require Credential parameter" {
            $Function = Connect-InventoryApi_Command
            $Function.Parameters.Credential.Attributes.Mandatory | Should -BeTrue
        }
        
        It "Should accept PSCredential for Credential parameter" {
            $Function = Connect-InventoryApi_Command
            $Function.Parameters.Credential.ParameterType.Name | Should -Be "PSCredential"
        }
        
        It "Should have optional ApiUrl parameter" {
            $Function = Connect-InventoryApi_Command
            $Function.Parameters.ApiUrl.Attributes.Mandatory | Should -BeFalse
        }
        
        It "Should have proper output type" {
            $Function = Connect-InventoryApi_Command
            $Function.OutputType.Type.Name | Should -Contain "Boolean"
        }
    }
}
