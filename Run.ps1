<#
.SYNOPSIS
Universal build, test, lint, and publish script for MetaNull.InventoryCli module.

.DESCRIPTION
This script provides a unified interface for common development tasks:
- Build: Builds the module using the module's Build.ps1 script
- Test: Runs all Pester tests in the module
- Lint: Runs PSScriptAnalyzer on the module source code
- Publish: Publishes the module using the module's Publish.ps1 script

.PARAMETER Action
The action to perform. Must be one of: 'Build', 'Test', 'Lint', 'Publish'.

.EXAMPLE
.\Run.ps1 Build
Builds the module with default settings.

.EXAMPLE
.\Run.ps1 Build -IncrementMajor
Builds the module with major version increment.

.EXAMPLE
.\Run.ps1 Test
Runs all Pester tests.

.EXAMPLE
.\Run.ps1 Lint
Runs PSScriptAnalyzer on the source code.

.EXAMPLE
.\Run.ps1 Publish -ApiKey "your-api-key"
Publishes the module to PSGallery.

.NOTES
This script forwards all additional parameters to the underlying scripts.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('Build', 'Test', 'Lint', 'Publish')]
    [string]$Action
)

# Get the script root directory
$ScriptRoot = $PSScriptRoot
$ModulePath = Join-Path $ScriptRoot "src" "MetaNull.InventoryCli"

# Ensure module path exists
if (-not (Test-Path $ModulePath)) {
    Write-Error "Module path not found: $ModulePath"
    exit 1
}

# Get remaining parameters to forward to the underlying scripts
$ForwardedParams = @{}
$BoundParameters = $PSBoundParameters.GetEnumerator() | Where-Object { $_.Key -ne 'Action' }
foreach ($Param in $BoundParameters) {
    $ForwardedParams[$Param.Key] = $Param.Value
}

# Also capture any unbound parameters
if ($args.Count -gt 0) {
    Write-Verbose "Additional arguments detected: $($args -join ', ')"
}

Write-Host "MetaNull.InventoryCli Development Script" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Green
Write-Host "Module Path: $ModulePath" -ForegroundColor Gray
Write-Host ""

try {
    switch ($Action.ToUpper()) {
        'BUILD' {
            Write-Host "🔨 Building Module..." -ForegroundColor Yellow
            
            $BuildScript = Join-Path $ModulePath "Build.ps1"
            if (-not (Test-Path $BuildScript)) {
                Write-Error "Build script not found: $BuildScript"
                exit 1
            }
            
            Write-Verbose "Executing: $BuildScript"
            Write-Verbose "Parameters: $($ForwardedParams | ConvertTo-Json -Compress)"
            
            Push-Location $ModulePath
            try {
                if ($ForwardedParams.Count -gt 0) {
                    $Result = & $BuildScript @ForwardedParams @args
                } else {
                    $Result = & $BuildScript @args
                }
                
                if ($Result) {
                    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
                    Write-Host "Built module location: $($Result.FullName)" -ForegroundColor Gray
                } else {
                    Write-Warning "Build script completed but returned no result"
                }
            } finally {
                Pop-Location
            }
        }
        
        'TEST' {
            Write-Host "🧪 Running Tests..." -ForegroundColor Yellow
            
            $TestPath = Join-Path $ModulePath "test"
            if (-not (Test-Path $TestPath)) {
                Write-Warning "Test directory not found: $TestPath"
                Write-Host "No tests to run." -ForegroundColor Yellow
                return
            }
            
            # Check if Pester is available
            if (-not (Get-Module -ListAvailable -Name Pester)) {
                Write-Host "Installing Pester module..." -ForegroundColor Yellow
                Install-Module -Name Pester -Force -Scope CurrentUser -RequiredVersion 5.5.0 -SkipPublisherCheck
            }
            
            Write-Verbose "Running Pester tests from: $TestPath"
            
            Push-Location $ModulePath
            try {
                $TestResults = Invoke-Pester -Path $TestPath -Output Detailed -PassThru
                
                Write-Host ""
                Write-Host "📊 Test Results Summary:" -ForegroundColor Cyan
                Write-Host "Total Tests: $($TestResults.TotalCount)" -ForegroundColor Gray
                Write-Host "Passed: $($TestResults.PassedCount)" -ForegroundColor Green
                Write-Host "Failed: $($TestResults.FailedCount)" -ForegroundColor $(if ($TestResults.FailedCount -gt 0) { 'Red' } else { 'Gray' })
                Write-Host "Skipped: $($TestResults.SkippedCount)" -ForegroundColor Yellow
                
                if ($TestResults.FailedCount -gt 0) {
                    Write-Host "❌ Some tests failed!" -ForegroundColor Red
                    exit 1
                } else {
                    Write-Host "✅ All tests passed!" -ForegroundColor Green
                }
            } finally {
                Pop-Location
            }
        }
        
        'LINT' {
            Write-Host "🔍 Running Code Analysis..." -ForegroundColor Yellow
            
            $SourcePath = Join-Path $ModulePath "source"
            if (-not (Test-Path $SourcePath)) {
                Write-Error "Source directory not found: $SourcePath"
                exit 1
            }
            
            # Check if PSScriptAnalyzer is available
            if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
                Write-Host "Installing PSScriptAnalyzer module..." -ForegroundColor Yellow
                Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
            }
            
            Write-Verbose "Running PSScriptAnalyzer on: $SourcePath"
            
            $AnalysisResults = Invoke-ScriptAnalyzer -Recurse -Path $SourcePath -ExcludeRule PSAvoidUsingConvertToSecureStringWithPlainText -Severity Error,Warning -Fix 
            
            if ($AnalysisResults) {
                Write-Host ""
                Write-Host "📋 Code Analysis Results:" -ForegroundColor Cyan
                Write-Host "Found $($AnalysisResults.Count) issues:" -ForegroundColor Yellow
                
                foreach ($Issue in $AnalysisResults) {
                    $SeverityColor = switch ($Issue.Severity) {
                        'Error' { 'Red' }
                        'Warning' { 'Yellow' }
                        default { 'Gray' }
                    }
                    
                    Write-Host ""
                    Write-Host "[$($Issue.Severity)] $($Issue.RuleName)" -ForegroundColor $SeverityColor
                    Write-Host "  File: $($Issue.ScriptPath)" -ForegroundColor Gray
                    Write-Host "  Line: $($Issue.Line), Column: $($Issue.Column)" -ForegroundColor Gray
                    Write-Host "  Message: $($Issue.Message)" -ForegroundColor White
                }
                
                Write-Host ""
                Write-Host "❌ Code analysis found issues that should be addressed!" -ForegroundColor Red
                exit 1
            } else {
                Write-Host "✅ No code analysis issues found!" -ForegroundColor Green
            }
        }
        
        'PUBLISH' {
            Write-Host "📦 Publishing Module..." -ForegroundColor Yellow
            
            $PublishScript = Join-Path $ModulePath "Publish.ps1"
            if (-not (Test-Path $PublishScript)) {
                Write-Error "Publish script not found: $PublishScript"
                exit 1
            }
            
            Write-Verbose "Executing: $PublishScript"
            Write-Verbose "Parameters: $($ForwardedParams | ConvertTo-Json -Compress)"
            
            Push-Location $ModulePath
            try {
                if ($ForwardedParams.Count -gt 0) {
                    & $PublishScript @ForwardedParams @args
                } else {
                    & $PublishScript @args
                }
                
                Write-Host "✅ Publish completed!" -ForegroundColor Green
            } finally {
                Pop-Location
            }
        }
        
        default {
            Write-Error "Unknown action: $Action"
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "🎉 $Action completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "❌ $Action failed with error:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack Trace:" -ForegroundColor Gray
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}
