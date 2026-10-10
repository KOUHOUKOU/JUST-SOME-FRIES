$taskRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$reviewRoot=Join-Path $taskRoot 'art_src/s6'
$baseGame=Join-Path $reviewRoot 'perf_game'
New-Item -ItemType Directory -Force $baseGame | Out-Null
Copy-Item -LiteralPath (Join-Path $taskRoot 'game/project.godot') -Destination $baseGame
foreach($dir in @('scripts','shaders')) {
 Copy-Item -LiteralPath (Join-Path $reviewRoot ('baseline/source/game/'+$dir)) -Destination $baseGame -Recurse -Force
}
Copy-Item -LiteralPath (Join-Path $taskRoot 'game/scenes') -Destination $baseGame -Recurse -Force
foreach($dir in @('assets','.godot')) {
 $link=Join-Path $baseGame $dir
 if(-not(Test-Path -LiteralPath $link)){New-Item -ItemType Junction -Path $link -Target (Join-Path $taskRoot ('game/'+$dir)) | Out-Null}
}
$priorApp=$env:APPDATA;$priorLocal=$env:LOCALAPPDATA;$priorTemp=$env:TEMP;$priorTmp=$env:TMP
try {
 $env:APPDATA=Join-Path $reviewRoot 'runtime/roaming';$env:LOCALAPPDATA=Join-Path $reviewRoot 'runtime/local';$env:TEMP=Join-Path $reviewRoot 'runtime/temp';$env:TMP=$env:TEMP
 $n=0
 foreach($version in @('before','after','after','before','before','after')) {
  $path=if($version -eq 'before'){$baseGame}else{Join-Path $taskRoot 'game'}
  $log=Join-Path $reviewRoot ('startup_'+$n+'_'+$version+'.log')
  & 'D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' --path $path --log-file $log --audio-driver Dummy --resolution 320x180 --max-fps 30 --quit-after 3 -- --art-review --cams 2>&1 | Out-File -Encoding utf8 (Join-Path $reviewRoot ('startup_'+$n+'_console.log'))
  Select-String -LiteralPath $log -Pattern 'island was built|SCRIPT ERROR|Parse Error' | ForEach-Object {$_.Line}
  $n++
 }
} finally {$env:APPDATA=$priorApp;$env:LOCALAPPDATA=$priorLocal;$env:TEMP=$priorTemp;$env:TMP=$priorTmp}
