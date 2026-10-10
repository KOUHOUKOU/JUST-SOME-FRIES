param([string]$Label='baseline',[ValidateSet('Cams','Import','Autotest','Contract','Bench')][string]$Mode='Cams')
$taskRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$reviewRoot=Join-Path $taskRoot 'art_src/s6'
$priorApp=$env:APPDATA;$priorLocal=$env:LOCALAPPDATA;$priorTemp=$env:TEMP;$priorTmp=$env:TMP
try {
 $env:APPDATA=Join-Path $reviewRoot 'runtime/roaming';$env:LOCALAPPDATA=Join-Path $reviewRoot 'runtime/local'
 $env:TEMP=Join-Path $reviewRoot 'runtime/temp';$env:TMP=$env:TEMP
 New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP | Out-Null
 $runArgs=@('--path',(Join-Path $taskRoot 'game'),'--log-file',(Join-Path $reviewRoot ($Label+'_'+$Mode+'.log')))
 if ($Mode -eq 'Import') {$runArgs+=@('--headless','--import')}
 elseif ($Mode -eq 'Bench') {$runArgs+=@('--headless','--script','res://scripts/art/s6_build_bench.gd','--','--art-s6')}
 elseif ($Mode -eq 'Contract') {$runArgs+=@('--headless','--quit-after','120','--script','res://scripts/art/s6_contract.gd','--','--art-s6')}
 else {$runArgs+=@('--audio-driver','Dummy','--resolution','960x540','--max-fps','30','--','--art-review','--art-s6',('--s6-label='+$Label));if($Mode -eq 'Autotest'){$runArgs+='--autotest'}else{$runArgs+='--cams'}}
 & 'D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' @runArgs
 $taskExit=$LASTEXITCODE
} finally {$env:APPDATA=$priorApp;$env:LOCALAPPDATA=$priorLocal;$env:TEMP=$priorTemp;$env:TMP=$priorTmp}
exit $taskExit
