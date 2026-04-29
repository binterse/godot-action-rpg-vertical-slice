$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$portableEngine = Join-Path $projectDir "tools\godot\engine\Godot_v4.6.2-stable_win64.exe"
$engine = if (Test-Path $portableEngine) { $portableEngine } else { "godot" }

Start-Process -FilePath $engine -WorkingDirectory $projectDir -ArgumentList @("--path", ".")
