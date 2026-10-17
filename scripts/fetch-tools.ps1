<#
.SYNOPSIS
    Download the build tools pinned in tools.json into external-tools/.
.DESCRIPTION
    Each archive's SHA-256 is checked before it is extracted. Tools already present are skipped.
    Also checks for the .NET SDK, which Spriggit needs to restore its serializer.
#>
param([string]$ToolsDir = (Join-Path $PSScriptRoot "..\external-tools"))
$ErrorActionPreference = "Stop"

$tools = Get-Content (Join-Path $PSScriptRoot "..\tools.json") -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null

foreach ($prop in $tools.PSObject.Properties) {
    $tool = $prop.Value
    if ($prop.Name.StartsWith("_") -or -not $tool.url) {
        if ($tool.folder) { Write-Host "$($prop.Name): no download yet, skipped" -ForegroundColor DarkGray }
        continue
    }
    $target = Join-Path $ToolsDir $tool.folder
    if (Test-Path $target) {
        Write-Host "$($prop.Name) $($tool.version): present" -ForegroundColor Green
        continue
    }
    $archive = Join-Path $ToolsDir "$($tool.folder).zip"
    Write-Host "$($prop.Name) $($tool.version): downloading" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $tool.url -OutFile $archive -UseBasicParsing
    if ($tool.sha256) {
        $actual = (Get-FileHash $archive -Algorithm SHA256).Hash
        if ($actual -ne $tool.sha256.ToUpper()) {
            Remove-Item $archive -Force
            throw "$($prop.Name): SHA-256 mismatch (expected $($tool.sha256), got $actual)"
        }
    }
    Expand-Archive -Path $archive -DestinationPath $target -Force
    Remove-Item $archive -Force
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue) -or -not (dotnet --list-sdks)) {
    Write-Warning "No .NET SDK found. Spriggit needs one to build the .esp files: winget install Microsoft.DotNet.SDK.9"
}
