# MetaNull.InventoryCli

[![Validate Pull Request](https://github.com/metanull/inventory-cli/actions/workflows/validate-pr.yml/badge.svg)](https://github.com/metanull/inventory-cli/actions/workflows/validate-pr.yml)
[![Publish to PSGallery](https://github.com/metanull/inventory-cli/actions/workflows/publish-psgallery.yml/badge.svg)](https://github.com/metanull/inventory-cli/actions/workflows/publish-psgallery.yml)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/MetaNull.InventoryCli.svg)](https://www.powershellgallery.com/packages/MetaNull.InventoryCli)

A PowerShell 5+ module designed to manage inventory operations, built following Microsoft's PowerShell best practices and guidelines.

## Features

- **PowerShell 5.1+ Compatible**: Works with PowerShell 5.1 and later versions
- **Standards Compliant**: Follows Microsoft's PowerShell best practices
- **Quality Assured**: All code passes PSScriptAnalyzer validation
- **Comprehensive Testing**: Full Pester test coverage
- **Automated CI/CD**: GitHub Actions for validation and publishing

## Installation

### From PowerShell Gallery (Recommended)

```powershell
Install-Module -Name MetaNull.InventoryCli -Repository PSGallery
```

### From Source

1. Clone the repository:
```bash
git clone https://github.com/metanull/inventory-cli.git
cd inventory-cli
```

2. Build the module:
```powershell
cd src/MetaNull.InventoryCli
.\Build.ps1
```

3. Import the built module:
```powershell
Import-Module .\build\MetaNull.InventoryCli\<version>\MetaNull.InventoryCli.psd1
```

## Usage

After installation, you can use the module's functions:

```powershell
# Import the module
Import-Module MetaNull.InventoryCli

# List available commands
Get-Command -Module MetaNull.InventoryCli

# Get help for specific functions
Get-Help Get-Dummy -Full
```

## Development

This module is built using [MetaNull.ModuleMaker](https://www.powershellgallery.com/packages/MetaNull.ModuleMaker), which provides a standardized structure and build process for PowerShell modules.

### Prerequisites

- PowerShell 5.1 or later
- [MetaNull.ModuleMaker](https://www.powershellgallery.com/packages/MetaNull.ModuleMaker)
- [PSScriptAnalyzer](https://www.powershellgallery.com/packages/PSScriptAnalyzer)
- [Pester](https://www.powershellgallery.com/packages/Pester) (v5.5.0)

### Project Structure

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

### Adding New Functions

1. Install MetaNull.ModuleMaker:
```powershell
Install-Module -Name MetaNull.ModuleMaker
```

2. Create a new function:
```powershell
New-FunctionBlueprint -ModulePath "src/MetaNull.InventoryCli" -FunctionName "Get-InventoryItem" -Visibility Public
```

3. Implement the function in the generated file
4. Write comprehensive Pester tests
5. Run validation and build:
```powershell
# Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path "src" -Recurse

# Run tests
Invoke-Pester -Path "src/MetaNull.InventoryCli/test"

# Build the module
.\src\MetaNull.InventoryCli\Build.ps1
```

### Code Quality Standards

- **PSScriptAnalyzer**: All code must pass without errors or warnings
- **Approved Verbs**: Function names must use [Microsoft's approved PowerShell verbs](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
- **CmdletBinding**: All functions must include `[CmdletBinding()]`
- **OutputType**: Functions should specify `[OutputType()]`
- **Help Documentation**: Comprehensive comment-based help required

### Testing

Run all tests:
```powershell
cd src/MetaNull.InventoryCli
Invoke-Pester -Path "test" -CodeCoverage "source/**/*.ps1"
```

### Building and Publishing

#### Build Module
```powershell
cd src/MetaNull.InventoryCli

# Build with default increment (build number)
.\Build.ps1

# Build with specific version increment
.\Build.ps1 -IncrementMinor
.\Build.ps1 -IncrementMajor
.\Build.ps1 -IncrementRevision
```

#### Publish to PSGallery
```powershell
# Get your API key from https://www.powershellgallery.com/account/apikeys
$ApiKey = Read-Host -AsSecureString "Enter PSGallery API Key"
$Credential = New-Object PSCredential("apikey", $ApiKey)

# Publish using the provided script
.\Publish.ps1 -Credential $Credential
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following the development guidelines
4. Ensure all tests pass and code quality checks succeed
5. Commit your changes: `git commit -am 'Add your feature'`
6. Push to the branch: `git push origin feature/your-feature-name`
7. Create a Pull Request

### Pull Request Requirements

- All code must pass PSScriptAnalyzer validation
- All tests must pass
- New functions must have corresponding tests
- Follow PowerShell best practices and naming conventions
- Include comprehensive help documentation

## CI/CD

This repository uses GitHub Actions for continuous integration and deployment:

- **PR Validation**: Automatically runs PSScriptAnalyzer and Pester tests on pull requests
- **Automated Publishing**: Publishes to PSGallery on push to main branch or manual trigger

### GitHub Secrets

For automated publishing, configure the following secret in your GitHub repository:

- `PSGALLERY_API_KEY`: Your PowerShell Gallery API key

## Version Management

Versions are automatically managed by the build script using semantic versioning:

- **Major**: Breaking changes (`Build.ps1 -IncrementMajor`)
- **Minor**: New features, backward compatible (`Build.ps1 -IncrementMinor`)
- **Build**: Automatic increment on each build
- **Revision**: Bug fixes (`Build.ps1 -IncrementRevision`)

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## Author

**Pascal Havelange**

- GitHub: [@metanull](https://github.com/metanull)
- Project: [inventory-cli](https://github.com/metanull/inventory-cli)

## Support

If you encounter any issues or have questions:

1. Check the [existing issues](https://github.com/metanull/inventory-cli/issues)
2. Create a new issue with detailed information
3. Follow the issue template if provided

## Changelog

See [releases](https://github.com/metanull/inventory-cli/releases) for version history and changes.
