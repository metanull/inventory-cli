# Test helper functions for loading and wrapping functions for testing

function Import-ModuleFunction {
    <#
    .SYNOPSIS
    Imports a module function for testing by wrapping it with the proper function declaration.
    
    .PARAMETER FunctionName
    The name of the function to import.
    
    .PARAMETER FunctionPath
    The path to the function file.
    
    .PARAMETER FunctionType
    The type of function (public or private).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FunctionName,
        
        [Parameter(Mandatory = $true)]
        [string]$FunctionPath,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('public', 'private')]
        [string]$FunctionType
    )
    
    if (-not (Test-Path $FunctionPath)) {
        throw "Function file not found: $FunctionPath"
    }
    
    # Read the function body
    $FunctionBody = Get-Content -Path $FunctionPath -Raw
    
    # Create the complete function definition
    $FunctionDefinition = @"
Function $FunctionName {
$FunctionBody
}
"@
    
    # Execute the function definition to create the function
    Invoke-Expression $FunctionDefinition -OutVariable null
    
    # Make the function available in global scope
    Set-Item -Path "Function:Global:$FunctionName" -Value (Get-Item "Function:$FunctionName").ScriptBlock
}

function Import-ModuleFunctions {
    <#
    .SYNOPSIS
    Imports multiple module functions for testing.
    
    .PARAMETER ModuleRoot
    The root path of the module source.
    
    .PARAMETER FunctionNames
    Array of function names to import.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleRoot,
        
        [Parameter(Mandatory = $true)]
        [string[]]$FunctionNames
    )
    
    # Load init script first for constants
    $InitPath = Join-Path $ModuleRoot "source\init\Init.ps1"
    if (Test-Path $InitPath) {
        . $InitPath
    }
    
    foreach ($FunctionName in $FunctionNames) {
        # Try to find the function in public first, then private
        $PublicPath = Join-Path $ModuleRoot "source\public\$FunctionName.ps1"
        $PrivatePath = Join-Path $ModuleRoot "source\private\$FunctionName.ps1"
        
        if (Test-Path $PublicPath) {
            Import-ModuleFunction -FunctionName $FunctionName -FunctionPath $PublicPath -FunctionType 'public'
            Write-Verbose "Imported public function: $FunctionName"
        }
        elseif (Test-Path $PrivatePath) {
            Import-ModuleFunction -FunctionName $FunctionName -FunctionPath $PrivatePath -FunctionType 'private'
            Write-Verbose "Imported private function: $FunctionName"
        }
        else {
            Write-Warning "Function file not found for: $FunctionName"
        }
    }
}
