<#
.SYNOPSIS
    Configure and build the examples.
.DESCRIPTION
    Enters a Visual Studio developer shell when one is installed (so cmake, ninja and cl.exe are on
    PATH), then runs the CMake preset. Without Visual Studio, CMake and Ninja must already be on PATH,
    which is enough for the papyrus preset.
.EXAMPLE
    ./build.ps1                       # Papyrus examples 01 and 02
    ./build.ps1 -Preset full          # adds the C++ SKSE plugin (03)
    ./build.ps1 -DeployDir "D:\MO2\mods"   # also copy each example into your mods folder
#>
param(
    [ValidateSet("papyrus", "full")]
    [string]$Preset = "papyrus",
    [string]$DeployDir = ""
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($vs) {
            Import-Module (Join-Path $vs "Common7\Tools\Microsoft.VisualStudio.DevShell.dll")
            Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64" | Out-Null
        }
    }
}

foreach ($tool in @("cmake", "ninja")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool not found. Install Visual Studio 2022, or: winget install Kitware.CMake Ninja-build.Ninja"
    }
}
if ($Preset -eq "full" -and -not $env:VCPKG_ROOT) {
    throw "The full preset needs VCPKG_ROOT set to a vcpkg checkout (git clone https://github.com/microsoft/vcpkg)."
}

$configureArgs = @("--preset", $Preset)
if ($DeployDir) { $configureArgs += "-DDEPLOY_DIR=$DeployDir" }
cmake @configureArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
cmake --build --preset $Preset
exit $LASTEXITCODE
