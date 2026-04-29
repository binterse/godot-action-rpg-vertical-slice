@echo off
setlocal
set "ENGINE=%~dp0tools\godot\engine\Godot_v4.6.2-stable_win64_console.exe"
if not exist "%ENGINE%" (
  set "ENGINE=godot"
)
pushd "%~dp0"
"%ENGINE%" --headless --path . --script res://tests/validate.gd
set "EXIT_CODE=%ERRORLEVEL%"
popd
exit /b %EXIT_CODE%
