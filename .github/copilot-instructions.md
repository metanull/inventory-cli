# GitHub Copilot Instructions for MetaNull.InventoryCli

## Repository Description

This repository hosts **MetaNull.InventoryCli**, a PowerShell 5+ module designed to manage inventory operations. The module is built following Microsoft's PowerShell best practices and guidelines, ensuring compatibility with PowerShell 5.1 and later versions.

## Module Architecture

### Structure Overview
The module follows a standardized structure generated by **MetaNull.ModuleMaker**:

```
src/MetaNull.InventoryCli/
├── Blueprint.psd1          # Module build configuration
├── Build.ps1              # Build script with version management
├── Publish.ps1            # Publishing script for PSGallery
├── Version.psd1           # Version tracking file
├── source/                # Source code directory
│   ├── init/              # Module initialization scripts
│   ├── private/           # Private functions (not exported)
│   ├── public/            # Public functions (exported)
│   └── class/             # PowerShell classes (if any)
├── test/                  # Test directory structure
│   ├── private/           # Tests for private functions
│   └── public/            # Tests for public functions
└── build/                 # Build output directory (generated)
```

## Development Context and Constraints

### MetaNull.ModuleMaker Usage
- **REQUIRED**: All module development must use MetaNull.ModuleMaker from PSGallery
- **Module Creation**: Use `New-ModuleBlueprint` with:
  - Name: `MetaNull.InventoryCli`
  - Description: `A PowerShell module to manage inventory`
  - Author: `Pascal Havelange`
  - ProjectUri: `https://github.com/metanull/inventory-cli`
- **Function Creation**: Use `New-FunctionBlueprint` to add new functions to the module
- **Build Process**: Always use the provided `Build.ps1` script which handles:
  - Version management (automatic build number increment)
  - Module manifest generation
  - Function export management
  - Dependency resolution

### PowerShell Standards Compliance
- **PowerShell Version**: Minimum PowerShell 5.1 compatibility required
- **Approved Verbs**: All function names MUST use Microsoft's approved PowerShell verbs
  - Valid examples: `Get-`, `Set-`, `New-`, `Remove-`, `Add-`, `Update-`, `Test-`, `Invoke-`
  - Invalid examples: `Download-`, `Upload-`, `Create-`, `Delete-`
- **CmdletBinding**: All functions must include `[CmdletBinding()]` attribute
- **OutputType**: All functions should specify `[OutputType()]` attribute
- **Help Documentation**: All functions must include comprehensive comment-based help

### Code Quality Requirements
- **PSScriptAnalyzer**: All code MUST pass PSScriptAnalyzer linting without errors
  - Use `Invoke-ScriptAnalyzer` to validate code quality
    - With the parameter `-ExcludeRule PSAvoidUsingConvertToSecureStringWithPlainText`
  - Address all warnings and errors before committing
- **Pester Testing**: All functions MUST have comprehensive Pester tests
  - Test coverage required for both public and private functions
  - Tests must be meaningful and cover edge cases
  - All tests must pass before code can be merged

### Testing Framework
- **Framework**: Use Pester for all unit and integration testing
- **Test Structure**: Follow the existing test pattern:
  - Tests are organized by visibility (public/private)
  - Each function has a corresponding `.Tests.ps1` file
  - Tests use the modular stub pattern for isolation
- **Test Execution**: Tests can be run using:
  - `Invoke-Pester` for local testing
  - GitHub Actions for CI/CD validation

### Version Management
- **Automatic Versioning**: The `Build.ps1` script manages version increments
- **Version Format**: Uses semantic versioning (Major.Minor.Build.Revision)
- **Build Numbers**: Build number is automatically incremented on each build
- **Version Parameters**:
  - `-IncrementMajor`: Major version increment (resets minor and revision)
  - `-IncrementMinor`: Minor version increment (resets revision)
  - `-IncrementRevision`: Revision increment

### Publishing Requirements
- **Target Repository**: PSGallery (PowerShell Gallery)
- **Authentication**: Uses API key authentication (never store keys in repository)
- **Publishing Script**: Use the provided `Publish.ps1` script
- **Dependencies**: Requires `Microsoft.PowerShell.PSResourceGet` module

## Development Workflow

### Adding New Functions
1. Use `New-FunctionBlueprint` from MetaNull.ModuleMaker
2. Implement function in appropriate directory (`public/` or `private/`)
3. Create comprehensive Pester tests
4. Run PSScriptAnalyzer validation
5. Execute all tests to ensure they pass
6. Build module using `Build.ps1`
7. Validate built module functionality

### Code Review Requirements
- All code must pass PSScriptAnalyzer without errors or warnings
- All functions must have corresponding tests
- All tests must pass
- Code must follow PowerShell best practices
- Function names must use approved PowerShell verbs
- Help documentation must be complete and accurate

### Continuous Integration
- Pull requests trigger automatic validation
- PSScriptAnalyzer runs on all PowerShell files
- All Pester tests execute automatically
- Builds must be successful before merge approval
- Publishing to PSGallery requires manual approval and secure API key

## Important Notes

- **Never commit API keys or credentials** to the repository
- **Always run tests** before submitting pull requests
- **Use the build script** for consistent module building
- **Follow the established directory structure** created by MetaNull.ModuleMaker
- **Maintain backward compatibility** with PowerShell 5.1
- **Document all public functions** with comprehensive help text
