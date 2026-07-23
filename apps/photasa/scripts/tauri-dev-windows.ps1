# Photasa Windows dev: load MSVC + NASM before `tauri dev` (ffmpeg-sys-next static build).
# Usage: pwsh -File scripts/tauri-dev-windows.ps1

$ErrorActionPreference = "Stop"

function Ensure-Llvm {
    if (Find-LibClangDir) {
        return Find-LibClangDir
    }

    Write-Host "LLVM/libclang not found, installing via winget..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id LLVM.LLVM -e --accept-package-agreements --accept-source-agreements --silent | Out-Host
        $dir = Find-LibClangDir
        if ($dir) { return $dir }
    }

    Write-Host "WARN: libclang not found; install LLVM.LLVM for bindgen (ffmpeg-sys-next)"
    return $null
}

function Find-LibClangDir {
    $candidates = @(
        "${env:ProgramFiles}\LLVM\bin",
        "${env:ProgramFiles(x86)}\LLVM\bin"
    )
    foreach ($dir in $candidates) {
        if (Test-Path (Join-Path $dir "libclang.dll")) {
            return $dir
        }
    }
    return $null
}

function Find-VcVarsAll {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $installPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
        if ($installPath) {
            $candidate = Join-Path $installPath "VC\Auxiliary\Build\vcvarsall.bat"
            if (Test-Path $candidate) {
                return $candidate
            }
        }
    }

    $fallbackRoots = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\18\Community",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools"
    )
    foreach ($root in $fallbackRoots) {
        $candidate = Join-Path $root "VC\Auxiliary\Build\vcvarsall.bat"
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "vcvarsall.bat not found. Install Visual Studio with Desktop development with C++."
}

function Find-NasmDir {
    $candidates = @(
        "${env:LOCALAPPDATA}\bin\NASM",
        "${env:ProgramFiles}\NASM",
        "${env:ProgramFiles(x86)}\NASM"
    )
    foreach ($dir in $candidates) {
        if (Test-Path (Join-Path $dir "nasm.exe")) {
            return $dir
        }
    }
    return $null
}

function Ensure-MsysBuildTools {
    $msysBash = "C:\msys64\usr\bin\bash.exe"
    if (-not (Test-Path $msysBash)) {
        Write-Host "MSYS2 not found, installing via winget..."
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install --id MSYS2.MSYS2 -e --accept-package-agreements --accept-source-agreements | Out-Host
        }
    }
    if (Test-Path $msysBash) {
        & $msysBash -lc "pacman -Sy --noconfirm make gawk diffutils" | Out-Host
        return
    }
    Ensure-Make | Out-Null
}

function Ensure-Make {
    if (Get-Command make -ErrorAction SilentlyContinue) {
        return
    }

    Write-Host "GNU make not found on PATH, installing via winget..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id ezwinports.make -e --accept-package-agreements --accept-source-agreements | Out-Host
        if (Get-Command make -ErrorAction SilentlyContinue) {
            return
        }
    }

    throw "GNU make not found. Run: winget install ezwinports.make"
}

function Ensure-Nasm {
    $script:nasmDir = Find-NasmDir
    if ($script:nasmDir) {
        $env:Path = "$($script:nasmDir);$env:Path"
        return $script:nasmDir
    }

    Write-Host "NASM not found on PATH, installing via winget..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id NASM.NASM -e --accept-package-agreements --accept-source-agreements | Out-Host
        $script:nasmDir = Find-NasmDir
        if ($script:nasmDir) {
            $env:Path = "$($script:nasmDir);$env:Path"
            return $script:nasmDir
        }
    }

    if (-not (Get-Command nasm -ErrorAction SilentlyContinue)) {
        throw "NASM not found. Run: winget install NASM.NASM"
    }
    return $null
}

$photasaRoot = Split-Path $PSScriptRoot -Parent
$vcvars = Find-VcVarsAll
$nasmDir = Ensure-Nasm
Ensure-MsysBuildTools | Out-Null
$libClangDir = Ensure-Llvm

Write-Host "MSVC env: $vcvars"
if ($nasmDir) { Write-Host "NASM dir: $nasmDir" }
if ($libClangDir) { Write-Host "LIBCLANG_PATH: $libClangDir" } else { Write-Host "WARN: libclang not found; install LLVM.LLVM for bindgen" }
Write-Host "Starting tauri dev (first FFmpeg build may take 5-15 min)..."

$extraPath = @()
if ($nasmDir) { $extraPath += $nasmDir }
$envLines = @()
if ($pathLine = $(if ($extraPath.Count -gt 0) { $joined = ($extraPath -join ";"); "set `"PATH=$joined;%PATH%`"`r`n" } else { "" })) { $envLines += $pathLine }
if ($libClangDir) { $envLines += "set `"LIBCLANG_PATH=$libClangDir`"`r`n" }
$envBlock = $envLines -join ""
$batchFile = Join-Path $env:TEMP "photasa-tauri-dev.cmd"
$batchContent = @"
@echo off
call "$vcvars" x64
if errorlevel 1 exit /b 1
$envBlock
cd /d "$photasaRoot"
pnpm exec tauri dev
"@
Set-Content -Path $batchFile -Value $batchContent -Encoding ASCII
cmd.exe /c $batchFile
exit $LASTEXITCODE
