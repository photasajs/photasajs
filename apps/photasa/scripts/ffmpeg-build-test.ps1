# Quick MSVC + NASM env test for ffmpeg-sys-next (no tauri dev).
$ErrorActionPreference = "Stop"
$vcvars = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat"
$nasmDir = "C:\Users\alber\AppData\Local\bin\NASM"
$libClangDir = "C:\Program Files\LLVM\bin"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$batch = Join-Path $env:TEMP "photasa-ffmpeg-build-test.cmd"
@"
@echo off
call "$vcvars" x64
if errorlevel 1 exit /b 1
set "PATH=$nasmDir;%PATH%"
set "LIBCLANG_PATH=$libClangDir"
cd /d "$repoRoot"
cargo build -p ffmpeg-sys-next
exit /b %ERRORLEVEL%
"@ | Set-Content -Path $batch -Encoding ASCII
cmd.exe /c $batch
exit $LASTEXITCODE
