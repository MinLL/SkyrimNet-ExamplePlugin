<#
.SYNOPSIS
    Write an edited .esp back to its Spriggit source.
.DESCRIPTION
    After you change an example's plugin in xEdit or the Creation Kit, run this on the .esp you
    edited. It finds the example whose spriggit/<Name> folder matches the file name and replaces
    that folder's contents. Review the diff with git before committing.
.EXAMPLE
    ./scripts/spriggit-sync.ps1 "D:\MO2\mods\ExampleBasics\ExampleBasics.esp"
#>
param([Parameter(Mandatory)][string]$EspPath)
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$name = [IO.Path]::GetFileNameWithoutExtension($EspPath)
$source = Get-ChildItem (Join-Path $root "examples") -Directory -Recurse -Filter $name |
    Where-Object { $_.Parent.Name -eq "spriggit" } | Select-Object -First 1
if (-not $source) { throw "No examples/*/spriggit/$name folder found for $EspPath" }

$tools = Get-Content (Join-Path $root "tools.json") -Raw | ConvertFrom-Json
$cli = Join-Path $root "external-tools\$($tools.spriggit.folder)\$($tools.spriggit.exe)"
if (-not (Test-Path $cli)) { throw "Spriggit not found. Run scripts/fetch-tools.ps1 first." }

$meta = Get-Content (Join-Path $source.FullName "spriggit-meta.json") -Raw | ConvertFrom-Json
& $cli convert-from-plugin -i $EspPath -o $source.FullName -g $meta.Release -p $meta.PackageName -v $meta.Version
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Updated $($source.FullName). Check 'git diff' before committing." -ForegroundColor Green
