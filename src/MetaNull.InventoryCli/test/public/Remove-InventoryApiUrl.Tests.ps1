BeforeAll {
    # Load test helpers
    . (Join-Path $PSScriptRoot "..\TestHelpers.ps1")
    
    # Import functions needed for testing
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-ModuleFunctions -ModuleRoot $ModuleRoot -FunctionNames @(
        'Remove-InventoryApiUrl',
        'Get-InventoryRegistryValue',
        'Set-InventoryRegistryValue'
    )
}

Describe "Remove-InventoryApiUrl" {
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
    
    Context "Removing existing API URL" {
        BeforeAll {
            # Set up a configured API URL
            Set-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl" -Value "https://test.example.com" | Out-Null
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
        BeforeAll {
            # Ensure no API URL is configured
            if (Test-Path (Join-Path $TestRegistryPath "Configuration")) {
                Remove-Item -Path (Join-Path $TestRegistryPath "Configuration") -Recurse -Force
            }
        }
        
        It "Should return true when URL is not configured" {
            $Result = Remove-InventoryApiUrl
            $Result | Should -Be $true
        }
    }
    
    Context "ShouldProcess support" {
        BeforeAll {
            # Set up a configured API URL
            Set-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl" -Value "https://test.example.com" | Out-Null
        }
        
        It "Should support WhatIf parameter" {
            $FunctionInfo = Get-Command Remove-InventoryApiUrl
            $FunctionInfo.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }
        
        It "Should support Confirm parameter" {
            $FunctionInfo = Get-Command Remove-InventoryApiUrl
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
            $FunctionInfo = Get-Command Remove-InventoryApiUrl
            $OutputType = $FunctionInfo.OutputType.Type.Name
            $OutputType | Should -Be "Boolean"
        }
        
        It "Should support SupportsShouldProcess" {
            $FunctionInfo = Get-Command Remove-InventoryApiUrl
            $SupportsShouldProcess = $FunctionInfo.Parameters.ContainsKey('WhatIf') -and $FunctionInfo.Parameters.ContainsKey('Confirm')
            $SupportsShouldProcess | Should -Be $true
        }
    }
    
    Context "Error handling" {
        BeforeAll {
            # Set up a configured API URL
            Set-InventoryRegistryValue -KeyName "Configuration" -ValueName "ApiUrl" -Value "https://test.example.com" | Out-Null
            
            # Mock Remove-ItemProperty to simulate failure
            function Remove-ItemProperty { throw "Registry access failed" }
        }
        
        AfterAll {
            # Remove the mock
            Remove-Item Function:\Remove-ItemProperty -ErrorAction SilentlyContinue
        }
        
        It "Should return false when registry removal fails" {
            $Result = Remove-InventoryApiUrl 2>$null
            $Result | Should -Be $false
        }
    }
}
