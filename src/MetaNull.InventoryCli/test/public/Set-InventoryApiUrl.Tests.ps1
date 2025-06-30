BeforeAll {
    # Load test helpers
    . (Join-Path $PSScriptRoot "..\TestHelpers.ps1")
    
    # Import functions needed for testing
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-ModuleFunctions -ModuleRoot $ModuleRoot -FunctionNames @(
        'Set-InventoryApiUrl',
        'Get-InventoryRegistryValue',
        'Set-InventoryRegistryValue'
    )
}

Describe "Set-InventoryApiUrl" {
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
    
    Context "Setting API URL with default value" {
        It "Should set the default URL when no parameter is provided" {
            $Result = Set-InventoryApiUrl
            $Result | Should -Be $true
            
            # Verify the value was set correctly
            $StoredUrl = Get-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl"
            $StoredUrl | Should -Be "http://127.0.0.1:8000"
        }
    }
    
    Context "Setting API URL with custom value" {
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
            $FunctionInfo = Get-Command Set-InventoryApiUrl
            $UrlParam = $FunctionInfo.Parameters['Url']
            $UrlParam.Attributes.Mandatory | Should -Be $false
        }
        
        It "Should have proper output type" {
            $FunctionInfo = Get-Command Set-InventoryApiUrl
            $OutputType = $FunctionInfo.OutputType.Type.Name
            $OutputType | Should -Be "Boolean"
        }
        
        It "Should work without parameters" {
            { Set-InventoryApiUrl } | Should -Not -Throw
        }
    }
    
    Context "Error handling" {
        BeforeAll {
            # Mock the registry function to simulate failure
            function Set-InventoryRegistryValue { return $false }
        }
        
        AfterAll {
            # Remove the mock
            Remove-Item Function:\Set-InventoryRegistryValue -ErrorAction SilentlyContinue
        }
        
        It "Should return false when registry write fails" {
            $Result = Set-InventoryApiUrl -Url "http://test.com"
            $Result | Should -Be $false
        }
    }
}
