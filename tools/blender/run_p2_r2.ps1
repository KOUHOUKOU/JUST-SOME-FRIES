param([ValidateSet('Import','Fish','VN','Fries','Tints','Contract')][string]$Mode='Fish', [int]$Iteration=1)
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$reviewRoot=Join-Path $projectRoot 'art_src/p2_review2'
$oldAppData=$env:APPDATA
$oldLocalData=$env:LOCALAPPDATA
try {
    $env:APPDATA=Join-Path $reviewRoot 'runtime/roaming'
    $env:LOCALAPPDATA=Join-Path $reviewRoot 'runtime/local'
    New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $runLog=Join-Path $reviewRoot ($Mode.ToLower()+"_i$Iteration.log")
    $argsList=@('--path',(Join-Path $projectRoot 'game'),'--log-file',$runLog)
    if ($Mode -eq 'Import') { $argsList+=@('--headless','--import') }
    elseif ($Mode -eq 'Contract') { $argsList+=@('--headless','--script','res://scripts/art/p2_r2_contract.gd','--') }
    else { $argsList+=@('--audio-driver','Dummy','--resolution','512x288','--max-fps','30','--','--art-review','--art-p2','--p2-r2','--cams',"--review-part=$Mode","--art-iteration=$Iteration") }
    $ErrorActionPreference='Continue'
    & 'D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' @argsList 2>&1 | ForEach-Object { $_.ToString() }
    $ErrorActionPreference='Stop'
    if ($LASTEXITCODE -ne 0) { throw "Godot failed: $LASTEXITCODE" }
    if (Select-String -LiteralPath $runLog -Pattern 'SCRIPT ERROR|SHADER ERROR' -Quiet) { throw "Godot script/shader error: $runLog" }
} finally { $env:APPDATA=$oldAppData; $env:LOCALAPPDATA=$oldLocalData }
