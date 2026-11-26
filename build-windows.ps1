[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$QtDirectory,

    [Parameter(Mandatory)]
    [string]$MinGWDirectory
)

$ErrorActionPreference = 'Stop'

function Invoke-Checked {
    param([string]$Executable, [string[]]$Arguments)

    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Executable exited with code $LASTEXITCODE."
    }
}

$qtBin = Join-Path (Resolve-Path -LiteralPath $QtDirectory).Path 'bin'
$mingwBin = Join-Path (Resolve-Path -LiteralPath $MinGWDirectory).Path 'bin'
$qmake = Join-Path $qtBin 'qmake.exe'
$windeployqt = Join-Path $qtBin 'windeployqt.exe'
$compiler = Join-Path $mingwBin 'g++.exe'
$make = Join-Path $mingwBin 'mingw32-make.exe'
$runtimeDlls = @('libgcc_s_seh-1.dll', 'libstdc++-6.dll', 'libwinpthread-1.dll', 'libgomp-1.dll')

$requiredTools = @($qmake, $windeployqt, $compiler, $make)
$requiredTools += $runtimeDlls | ForEach-Object { Join-Path $mingwBin $_ }
foreach ($path in $requiredTools) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing $path. Install Qt 5.15.2 and its matching MinGW 8.1 x64 toolchain."
    }
}

$dist = Join-Path $PSScriptRoot 'dist'
$build = Join-Path $dist ('.build-windows-' + [Guid]::NewGuid().ToString('N'))
$packageName = 'TexasSolverGui-windows-x64'
$package = Join-Path $build $packageName
$archive = Join-Path $build "$packageName.zip"
$finalArchive = Join-Path $dist "$packageName.zip"
$previousPath = $env:PATH

New-Item -ItemType Directory -Path $build -Force | Out-Null
try {
    $env:PATH = "$qtBin;$mingwBin;$previousPath"
    $compilerTarget = Invoke-Checked $compiler @('-dumpmachine')
    if ($compilerTarget -ne 'x86_64-w64-mingw32') {
        throw "Expected a MinGW x64 compiler, found '$compilerTarget'."
    }

    Push-Location -LiteralPath $build
    try {
        $project = Join-Path $PSScriptRoot 'TexasSolverGui.pro'
        Invoke-Checked $qmake @('-spec', 'win32-g++', $project, 'CONFIG+=release', 'CONFIG-=debug', 'CONFIG-=debug_and_release', 'DESTDIR=release')
        Invoke-Checked $make @("-j$([Environment]::ProcessorCount)")
    }
    finally {
        Pop-Location
    }

    New-Item -ItemType Directory -Path $package | Out-Null
    Copy-Item -LiteralPath (Join-Path $build 'release/TexasSolverGui.exe') -Destination $package
    $application = Join-Path $package 'TexasSolverGui.exe'
    # Qt 5.15.2's explicit release filter rejects the official MinGW platform plugin.
    Invoke-Checked $windeployqt @('--no-compiler-runtime', $application)

    # windeployqt does not discover application-specific OpenMP runtime dependencies.
    foreach ($dll in $runtimeDlls) {
        Copy-Item -LiteralPath (Join-Path $mingwBin $dll) -Destination $package
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'LICENSE') -Destination $package
    foreach ($file in @('Qt5Core.dll', 'Qt5Gui.dll', 'Qt5Widgets.dll', 'platforms/qwindows.dll')) {
        if (-not (Test-Path -LiteralPath (Join-Path $package $file) -PathType Leaf)) {
            throw "Missing Windows package dependency: $file"
        }
    }

    Compress-Archive -LiteralPath $package -DestinationPath $archive
    Move-Item -LiteralPath $archive -Destination $finalArchive -Force
    Write-Output "Built: $finalArchive"
}
finally {
    $env:PATH = $previousPath
    Remove-Item -LiteralPath $build -Recurse -Force
}
