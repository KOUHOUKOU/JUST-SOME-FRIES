param([ValidateSet('Import','Color','Review','Contract','Autotest')][string]$Mode='Review')
$taskRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$reviewRoot=Join-Path $taskRoot 'art_src/s1/round_2'
$priorApp=$env:APPDATA;$priorLocal=$env:LOCALAPPDATA;$priorTemp=$env:TEMP;$priorTmp=$env:TMP
try {
 $env:APPDATA=Join-Path $reviewRoot 'runtime/roaming';$env:LOCALAPPDATA=Join-Path $reviewRoot 'runtime/local'
 $env:TEMP=Join-Path $reviewRoot 'runtime/temp';$env:TMP=$env:TEMP
 New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP | Out-Null
 $runArgs=@('--path',(Join-Path $taskRoot 'game'),'--log-file',(Join-Path $reviewRoot ($Mode.ToLower()+'.log')))
 if ($Mode -eq 'Import') {$runArgs+=@('--headless','--import')}
 elseif ($Mode -eq 'Contract') {$runArgs+=@('--headless','--script','res://scripts/art/s1_r2_contract.gd')}
 else {
  $runArgs+=@('--audio-driver','Dummy','--resolution','512x288','--max-fps','30','--','--art-review','--art-s1','--s1-r2')
  if ($Mode -eq 'Autotest') {$runArgs+='--autotest'} else {$runArgs+='--cams'}
  if ($Mode -eq 'Color') {$runArgs+='--s1-color'}
 }
 & 'D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' @runArgs
 $taskExit=$LASTEXITCODE
} finally {$env:APPDATA=$priorApp;$env:LOCALAPPDATA=$priorLocal;$env:TEMP=$priorTemp;$env:TMP=$priorTmp}
exit $taskExit
