param([ValidateSet('Import', 'Cams', 'Autotest')][string]$Mode = 'Cams')
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$reviewRoot = Join-Path $projectRoot 'art_src/p0'
$godotExe = 'D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$oldAppData = $env:APPDATA
$oldLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $reviewRoot 'runtime/roaming'
    $env:LOCALAPPDATA = Join-Path $reviewRoot 'runtime/local'
    New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $argsList = @('--path', (Join-Path $projectRoot 'game'), '--log-file', (Join-Path $reviewRoot ($Mode.ToLower() + '.log')))
    if ($Mode -eq 'Import') {
        $argsList += @('--headless', '--import')
    } else {
        $argsList += @('--audio-driver', 'Dummy', '--resolution', '512x288', '--max-fps', '30', '--', '--art-review')
        if ($Mode -eq 'Cams') { $argsList += @('--cams', '--art-p0') }
        else { $argsList += '--autotest' }
    }
    & $godotExe @argsList
    if ($LASTEXITCODE -ne 0) { throw "Godot $Mode failed: exit $LASTEXITCODE" }
} finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalData
}
