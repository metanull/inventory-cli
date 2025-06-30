BeforeAll {
    # Load test helpers
    . (Join-Path $PSScriptRoot "..\TestHelpers.ps1")
    
    # Import functions needed for testing
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-ModuleFunctions -ModuleRoot $ModuleRoot -FunctionNames @(
        'Get-InventoryApiUrl',
        'Get-InventoryRegistryValue',
        'Set-InventoryRegistryValue'
    )
}

Describe "Get-InventoryApiUrl" {
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
        # Create a test registry path by appending '.test' to the module registry path
        $TestRegistryPath = $INVENTORY_CLI_REGISTRY_PATH + ".test"
        
        # Clean up any existing test keys
        if (Test-Path $TestRegistryPath) {
            Remove-Item -Path $TestRegistryPath -Recurse -Force
        }
        
        # Mock the module constant for testing
        Set-Variable -Name INVENTORY_CLI_REGISTRY_PATH -Value $TestRegistryPath -Force
    }
    
    AfterAll {
        # Create a test registry path by appending '.test' to the module registry path
        $TestRegistryPath = $INVENTORY_CLI_REGISTRY_PATH + ".test"
        
        # Clean up test registry keys
        if (Test-Path $TestRegistryPath) {
            Remove-Item -Path $TestRegistryPath -Recurse -Force
        }
    }
    
    Context "When API URL is not configured" {
        BeforeAll {
            # Ensure no API URL is configured
            if (Test-Path (Join-Path $TestRegistryPath "Configuration")) {
                Remove-Item -Path (Join-Path $TestRegistryPath "Configuration") -Recurse -Force
            }
        }
        
        It "Should return the default URL" {
            $Result = Get-InventoryApiUrl
            $Result | Should -Be "http://127.0.0.1:8000"
        }
    }
    
    Context "When API URL is configured" {
        BeforeAll {
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
        BeforeAll {
            # Mock the registry function to simulate failure
            function Get-InventoryRegistryValue { throw "Registry access failed" }
        }
        
        AfterAll {
            # Remove the mock
            Remove-Item Function:\Get-InventoryRegistryValue -ErrorAction SilentlyContinue
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
            $FunctionInfo = Get-Command Get-InventoryApiUrl
            $OutputType = $FunctionInfo.OutputType.Type.Name
            $OutputType | Should -Be "String"
        }
    }
}
