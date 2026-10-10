param([ValidateSet('OriginalImport','OriginalCams','FinalCams','Film','Build','Web','Smoke','OriginalPack')][string]$Mode,[switch]$Details)
$taskRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$out=Join-Path $taskRoot 'art_src/final'
$engine='D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$saved=@{}; foreach($k in 'APPDATA','LOCALAPPDATA','TEMP','TMP'){$saved[$k]=[Environment]::GetEnvironmentVariable($k)}
try {
 $env:APPDATA=Join-Path $out 'runtime/roaming';$env:LOCALAPPDATA=Join-Path $out 'runtime/local';$env:TEMP=Join-Path $out 'runtime/temp';$env:TMP=$env:TEMP
 New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP | Out-Null
 $project=Join-Path $taskRoot 'game'
 if($Mode.StartsWith('Original')){$project=Join-Path $taskRoot 'art_src/_orig_build'}
 $runArgs=@('--path',$project,'--log-file',(Join-Path $out ($Mode+'.log')))
 switch($Mode){
  'OriginalImport' {$runArgs+=@('--headless','--import')}
  'OriginalPack' { & python (Join-Path $PSScriptRoot 's4_baseline_pack.py'); exit $LASTEXITCODE }
  'OriginalCams' {$runArgs+=@('--audio-driver','Dummy','--resolution','960x540','--max-fps','30','--','--cams','--full','--art-s4','--s4-label=original',('--s4-root='+$taskRoot.Replace('\','/')))}
  'FinalCams' {$runArgs+=@('--audio-driver','Dummy','--resolution','960x540','--max-fps','30','--','--cams','--full','--art-s4','--s4-label=final',('--s4-root='+$taskRoot.Replace('\','/')))}
  'Film' {$runArgs+=@('--resolution','1280x720','--max-fps','30','--write-movie',(Join-Path $taskRoot 'film/art_remaster_raw.avi'),'--fixed-fps','30','--','--film','--seg=6','--movie-fps=30')}
  'Build' { & (Join-Path $taskRoot 'BUILD.bat') 2>&1 | Out-File -Encoding utf8 (Join-Path $out 'Build_console.log'); exit $LASTEXITCODE }
  'Web' {
   # Read installed templates, copy to isolated user data; no downloads or external writes.
   $templateSource=Join-Path $saved.APPDATA 'Godot/export_templates/4.7.1.stable'
   $templateTarget=Join-Path $env:APPDATA 'Godot/export_templates/4.7.1.stable'
   New-Item -ItemType Directory -Force $templateTarget | Out-Null
   foreach($n in 'version.txt','web_nothreads_release.zip','web_nothreads_debug.zip'){Copy-Item -LiteralPath (Join-Path $templateSource $n) -Destination $templateTarget -Force}
   $runArgs+=@('--headless','--export-release','Web',(Join-Path $taskRoot 'web/index.html'))
  }
  'Smoke' {$engine=Join-Path $taskRoot 'build/JustSomeFries.exe';$runArgs=@('--headless','--path',(Join-Path $taskRoot 'build'),'--log-file',(Join-Path $out 'Smoke.log'),'--quit-after','8','--','--s4-smoke')}
 }
 if($Details){$runArgs+='--s4-details'}
 & $engine @runArgs 2>&1 | Out-File -Encoding utf8 (Join-Path $out ($Mode+'_console.log'))
 $code=$LASTEXITCODE
 Write-Output "$Mode exit=$code"
 Select-String -LiteralPath (Join-Path $out ($Mode+'.log')) -Pattern 'island was built|SCRIPT ERROR|Parse Error|COMPLETE|film|ERROR|Movie' | Select-Object -Last 16 | ForEach-Object {$_.Line}
 exit $code
} finally {foreach($k in $saved.Keys){[Environment]::SetEnvironmentVariable($k,$saved[$k])}}
