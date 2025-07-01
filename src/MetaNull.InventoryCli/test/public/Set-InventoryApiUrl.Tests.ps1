Describe "Set-InventoryApiUrl" -Tag "UnitTest" {

    BeforeAll {
        $script:INVENTORY_CLI_REGISTRY_PATH = "HKCU:\SOFTWARE\metanull.test\inventory-cli"

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\public")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName
        
        # Define the Module function by dot sourcing it
        Function Set-InventoryApiUrl {
            . $Script @args | write-Output
        }
        # Define an accessor to the function's properties
        Function Set-InventoryApiUrl_Command {
            Get-Command $Script
        }

        # Define stub functions for dependencies
        Function Set-InventoryRegistryValue {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Set-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
        Function Get-InventoryRegistryValue {
            $RegistryScript = Join-Path ($ScriptDirectory | Split-Path -Parent) 'private\Get-InventoryRegistryValue.ps1'
            . ($RegistryScript) @args | write-Output
        }
    }
    
    
    Context "Setting API URL with default value" {
        BeforeEach {
            # Clean up test registry
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
        }
        
        It "Should set the default URL when no parameter is provided" {
            $Result = Set-InventoryApiUrl
            $Result | Should -Be $true
            
            # Verify the value was set correctly
            $StoredUrl = Get-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl"
            $StoredUrl | Should -Be "http://127.0.0.1:8000"
        }
    }
    
    Context "Setting API URL with custom value" {
        BeforeEach {
            # Clean up test registry
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
        }
        
        It "Should set a custom HTTP URL" {
            $TestUrl = "http://api.example.com:8080"
            $Result = Set-InventoryApiUrl -Url $TestUrl
            $Result | Should -Be $true
            
            # Verify the value was set correctly
            $StoredUrl = Get-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl"
            $StoredUrl | Should -Be $TestUrl
        }
        
        It "Should set a custom HTTPS URL" {
            $TestUrl = "https://secure-api.example.com:8443"
            $Result = Set-InventoryApiUrl -Url $TestUrl
            $Result | Should -Be $true
            
            # Verify the value was set correctly
            $StoredUrl = Get-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl"
            $StoredUrl | Should -Be $TestUrl
        }
    }
    
    Context "URL validation" {
        BeforeEach {
            # Clean up test registry
            if (Test-Path $script:INVENTORY_CLI_REGISTRY_PATH) {
                Remove-Item -Path $script:INVENTORY_CLI_REGISTRY_PATH -Recurse -Force
            }
        }
        
        It "Should reject invalid URL formats" {
            $InvalidUrls = @(
                "not-a-url",
                "ftp://invalid.protocol.com",
                "file://local/path"
            )
            
            foreach ($InvalidUrl in $InvalidUrls) {
                $Result = Set-InventoryApiUrl -Url $InvalidUrl 2>$null
                $Result | Should -Be $false -Because "URL '$InvalidUrl' should be rejected"
            }
        }
        
        It "Should reject null and empty URLs" {
            # These should throw validation exceptions due to ValidateNotNullOrEmpty attribute
            { Set-InventoryApiUrl -Url "" } | Should -Throw
            { Set-InventoryApiUrl -Url $null } | Should -Throw
        }
        
        It "Should accept valid HTTP URLs" {
            $ValidUrls = @(
                "http://localhost",
                "http://127.0.0.1:8000",
                "http://api.example.com:8080",
                "https://secure.example.com",
                "https://api.example.com:443"
            )
            
            foreach ($ValidUrl in $ValidUrls) {
                $Result = Set-InventoryApiUrl -Url $ValidUrl
                $Result | Should -Be $true -Because "URL '$ValidUrl' should be accepted"
            }
        }
    }
    
    Context "Parameter validation" {
        It "Should have optional Url parameter" {
            $FunctionInfo = Set-InventoryApiUrl_Command
            $UrlParam = $FunctionInfo.Parameters['Url']
            $UrlParam.Attributes.Mandatory | Should -Be $false
        }
        
        It "Should have proper output type" {
            $FunctionInfo = Set-InventoryApiUrl_Command
            $OutputType = $FunctionInfo.OutputType.Type.Name
            $OutputType | Should -Be "Boolean"
        }
        
        It "Should work without parameters" {
            { Set-InventoryApiUrl } | Should -Not -Throw
        }
    }
}
