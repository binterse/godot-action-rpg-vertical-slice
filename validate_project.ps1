$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$portableEngine = Join-Path $projectDir "tools\godot\engine\Godot_v4.6.2-stable_win64_console.exe"
$engine = if (Test-Path $portableEngine) { $portableEngine } else { "godot" }

Push-Location $projectDir
try {
    & $engine --headless --path . --script res://tests/validate.gd
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
