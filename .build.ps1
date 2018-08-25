try { Import-Module -Name InvokeBuild -ErrorAction Stop}
catch { throw $_ }

$ErrorActionPreference = 'Stop'

#region ModuleInfo
$moduleName = "PSRotateLog"
$moduleVersion = "1.1.6"
# endregion

$moduleContent = @()
$modulePath = "$($Variable:PSScriptRoot)\Release\$moduleName\$moduleVersion"
$sourceRoot = "$($Variable:PSScriptRoot)\Source"
$manifest = @{
    Path = "$modulePath\$moduleName.psd1"
    RootModule = "$moduleName.psm1"
    Author = 'Vasily Larionov'
    ModuleVersion = $moduleVersion
    Description = 'Remove or compress old IIS logs'
    FunctionsToExport = @()
    GUID = '5e311ef9-78cd-4aa6-8637-91f9bbbba508'
}

task Cleanup {
    if (Test-Path -Path $modulePath)
    {
        Remove-Item -Path $modulePath -Recurse -Force
    }
}

task Configure {
    if (!(Test-Path -Path $modulePath -PathType Container))
    {
        New-Item -Path $modulePath -ItemType Directory
    }

}

task GetPublicFunctions {
    $Exported = @()
    Get-ChildItem $sourceRoot -Recurse -Include "*.ps1" -Exclude '*.private.ps1', '*.Tests.ps1' -File | ForEach-Object {
        $manifest.FunctionsToExport += ([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [System.Management.Automation.PSReference]$null, [System.Management.Automation.PSReference]$null)).FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object {$_.Name}
    }

}

task BuildPSM {
    Get-ChildItem -Path $sourceRoot -File -Recurse -Include "*.ps1" -Exclude '*.Tests.ps1' -ErrorAction Stop|ForEach-Object {
        $moduleContent += Get-Content -Path $_
    }
    Set-Content -Path "$modulePath\$moduleName.psm1" -Value $moduleContent -ErrorAction Stop
}

task BuildPSD {
    New-ModuleManifest @manifest -ErrorAction Stop

}

# Run default task
task . Cleanup, Configure, GetPublicFunctions, BuildPSM, BuildPSD
