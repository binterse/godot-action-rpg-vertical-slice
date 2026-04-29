@echo off
setlocal
set "ENGINE=%~dp0tools\godot\engine\Godot_v4.6.2-stable_win64.exe"
if not exist "%ENGINE%" (
  set "ENGINE=godot"
)
pushd "%~dp0"
start "" "%ENGINE%" --path .
popd
