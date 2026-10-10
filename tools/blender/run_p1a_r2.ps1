param([ValidateSet('Import','Colour','Review','Joints','Contract')][string]$Mode='Colour', [ValidateRange(1,3)][int]$Iteration=1)
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$reviewRoot=Join-Path $projectRoot 'art_src/p1a_review2'
$oldAppData=$env:APPDATA
$oldLocalData=$env:LOCALAPPDATA
try {
    $env:APPDATA=Join-Path $reviewRoot 'runtime/roaming'
    $env:LOCALAPPDATA=Join-Path $reviewRoot 'runtime/local'
    New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $runLog=Join-Path $reviewRoot ($Mode.ToLower()+"_i$Iteration.log")
    $argsList=@('--path',(Join-Path $projectRoot 'game'),'--log-file',$runLog)
    if ($Mode -eq 'Import') { $argsList+=@('--headless','--import') }
    elseif ($Mode -eq 'Contract') { $argsList+=@('--headless','--script','res://scripts/art/p1a_contract.gd') }
    else {
        $argsList+=@('--audio-driver','Dummy','--resolution','960x540','--max-fps','30','--','--art-review','--art-p1a','--art-r2',"--art-iteration=$Iteration",'--cams')
        if ($Mode -eq 'Colour') { $argsList+='--colour-only' }
        if ($Mode -eq 'Joints') { $argsList+='--joints-only' }
    }
    & 'D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' @argsList
    if ($LASTEXITCODE -ne 0) { throw "Godot failed: $LASTEXITCODE" }
    if (Select-String -LiteralPath $runLog -Pattern 'SCRIPT ERROR|SHADER ERROR' -Quiet) { throw "Godot script/shader error; inspect $runLog" }
} finally { $env:APPDATA=$oldAppData; $env:LOCALAPPDATA=$oldLocalData }
