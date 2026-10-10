param([ValidateSet('Import','Palette','Cams','Autotest','Contract','Details')][string]$Mode='Palette', [int]$Iteration=1)
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$reviewRoot=Join-Path $projectRoot 'art_src/p1a'
$oldAppData=$env:APPDATA
$oldLocalData=$env:LOCALAPPDATA
try {
    $env:APPDATA=Join-Path $reviewRoot 'runtime/roaming'
    $env:LOCALAPPDATA=Join-Path $reviewRoot 'runtime/local'
    New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $argsList=@('--path',(Join-Path $projectRoot 'game'),'--log-file',(Join-Path $reviewRoot ($Mode.ToLower()+"_i$Iteration.log")))
    if ($Mode -eq 'Import') { $argsList+=@('--headless','--import') }
    elseif ($Mode -eq 'Contract') { $argsList+=@('--headless','--script','res://scripts/art/p1a_contract.gd') }
    else {
        $argsList+=@('--audio-driver','Dummy','--resolution','512x288','--max-fps','30','--','--art-review','--art-p1a',"--art-iteration=$Iteration")
        if ($Mode -eq 'Details') { $argsList+='--p1a-details' }
        if ($Mode -eq 'Autotest') { $argsList+='--autotest' }
        else { $argsList+='--cams'; if ($Mode -eq 'Palette') { $argsList+='--palette-only' } }
    }
    & 'D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' @argsList
    if ($LASTEXITCODE -ne 0) { throw "Godot failed: $LASTEXITCODE" }
    $runLog=Join-Path $reviewRoot ($Mode.ToLower()+"_i$Iteration.log")
    if (Select-String -LiteralPath $runLog -Pattern "SCRIPT ERROR|SHADER ERROR" -Quiet) { throw "Godot script/shader error; inspect $runLog" }
} finally { $env:APPDATA=$oldAppData; $env:LOCALAPPDATA=$oldLocalData }
