param([string]$Label='baseline',[ValidateSet('Cams','Import','Autotest','Cold','Contract','Bake')][string]$Mode='Cams')
$taskRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$reviewRoot=Join-Path $taskRoot 'art_src/s7'
$priorApp=$env:APPDATA;$priorLocal=$env:LOCALAPPDATA;$priorTemp=$env:TEMP;$priorTmp=$env:TMP
try {
 $env:APPDATA=Join-Path $reviewRoot 'runtime/roaming';$env:LOCALAPPDATA=Join-Path $reviewRoot 'runtime/local';$env:TEMP=Join-Path $reviewRoot 'runtime/temp';$env:TMP=$env:TEMP
 New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP | Out-Null
 $count=if($Mode -eq 'Cold'){5}else{1}
 for($n=0;$n -lt $count;$n++) {
  $tag=if($Mode -eq 'Cold'){$Label+'_cold_'+$n}else{$Label+'_'+$Mode}
  $runArgs=@('--path',(Join-Path $taskRoot 'game'),'--log-file',(Join-Path $reviewRoot ($tag+'.log')))
  if($Mode -eq 'Import'){$runArgs+=@('--headless','--import')}
  elseif($Mode -eq 'Contract'){$runArgs+=@('--headless','--max-fps','30','--quit-after','3000','--script','res://scripts/art/s7_contract.gd','--','--art-s7')}
  elseif($Mode -eq 'Bake'){$runArgs+=@('--headless','--script','res://scripts/art/s7_bake.gd','--','--art-s7','--s7-bake','--s7-profile')}
  else {
   $runArgs+=@('--audio-driver','Dummy','--resolution','960x540','--max-fps','30')
   if($Mode -eq 'Cold'){$runArgs+=@('--quit-after','3')}
   $runArgs+=@('--','--art-review','--art-s7','--s7-profile',('--s7-label='+$Label))
   if($Mode -eq 'Autotest'){$runArgs+='--autotest'}elseif($Mode -ne 'Cold'){$runArgs+='--cams'}
  }
  & 'D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' @runArgs 2>&1 | Out-File -Encoding utf8 (Join-Path $reviewRoot ($tag+'_console.log'))
  Select-String -LiteralPath (Join-Path $reviewRoot ($tag+'.log')) -Pattern 'island was built|slowest build|S7_PROFILE|S7_FIRST_FRAME|SCRIPT ERROR|Parse Error|COMPLETE|AUTOTEST.*(PASS|FAIL|ended|24/)' | Select-Object -First 12 | ForEach-Object {$_.Line}
  if(Select-String -Quiet -LiteralPath (Join-Path $reviewRoot ($tag+'.log')) -Pattern 'SCRIPT ERROR|Parse Error'){throw 'Run failed; inspect log before continuing'}
 }
} finally {$env:APPDATA=$priorApp;$env:LOCALAPPDATA=$priorLocal;$env:TEMP=$priorTemp;$env:TMP=$priorTmp}
