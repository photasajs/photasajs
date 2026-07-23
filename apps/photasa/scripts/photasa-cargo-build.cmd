@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
set "PATH=C:\Users\alber\AppData\Local\bin\NASM;%PATH%"
set "LIBCLANG_PATH=C:\Program Files\LLVM\bin"
cd /d "C:\Users\alber\ws\prj\picasa\picasa-vue\apps\photasa\src-tauri"
cargo build
