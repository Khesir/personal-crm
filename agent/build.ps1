param(
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$ScriptDir = $PSScriptRoot

Set-Location $ScriptDir

if ($Clean -and (Test-Path 'dist')) {
    Remove-Item -Recurse -Force 'dist'
}

if (-not (Get-Command pyinstaller -ErrorAction SilentlyContinue)) {
    pip install pyinstaller
}

pyinstaller build.spec --distpath dist --workpath build\pyinstaller_work --noconfirm

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build succeeded: $ScriptDir\dist\avyn-agent.exe"
} else {
    Write-Error "Build failed (exit $LASTEXITCODE)"
}
