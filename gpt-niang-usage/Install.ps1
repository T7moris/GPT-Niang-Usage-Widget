param([switch]$CheckOnly)
$ErrorActionPreference='Stop'
$appDir=$PSScriptRoot
$localData=[Environment]::GetFolderPath('LocalApplicationData')
if(!$localData){throw 'Local application data folder unavailable.'}
$dataDir=Join-Path $localData 'GPTNiangUsage\state'
# Preserve an existing installation's chosen data directory on an in-place upgrade.
$previousConfig=Join-Path $appDir 'installation.json'
if(Test-Path -LiteralPath $previousConfig){
  $previous=Get-Content -LiteralPath $previousConfig -Raw -Encoding UTF8|ConvertFrom-Json
  if([IO.Path]::GetFullPath([string]$previous.appDir)-ine [IO.Path]::GetFullPath($appDir)){throw 'Installation belongs to a different folder. Disable it before moving.'}
  $dataDir=[IO.Path]::GetFullPath([string]$previous.dataDir)
}
$nodeCommand=Get-Command node.exe -ErrorAction SilentlyContinue
if(!$nodeCommand){throw 'Node.js 20 or later is required. Install Node.js and reopen the installer.'}
$node=$nodeCommand.Source
$nodeMajor=[int]((& $node --version).TrimStart('v').Split('.')[0])
if($nodeMajor-lt 20){throw 'Node.js 20 or later is required.'}
$codexCommand=Get-Command codex.exe -ErrorAction SilentlyContinue
$codex=if($codexCommand){$codexCommand.Source}else{$null}
if(!$codex){
  $bundled=Join-Path $localData 'OpenAI\Codex\bin'
  if(Test-Path -LiteralPath $bundled){$codex=(Get-ChildItem -LiteralPath $bundled -Filter codex.exe -File -Recurse|Sort-Object LastWriteTimeUtc -Descending|Select-Object -First 1).FullName}
}
if(!$codex){throw 'Codex executable unavailable. Install and open the Codex desktop app first.'}
$marketplaceRoot=Split-Path $appDir -Parent
foreach($file in @('widget.ps1','widget.xaml','launch.vbs','supervisor.vbs','assets\gpt-dragon-niang-bust.png','assets\quotes.json','assets\press.wav','assets\release.wav','runtime\quotes.ps1','runtime\ui-settings.ps1','runtime\audio.ps1','runtime\host-layer.ps1','runtime\supervisor.ps1','runtime\supervisor-task.ps1','runtime\start-supervisor.ps1','runtime\metadata.mjs','runtime\mcp.mjs','.codex-plugin\plugin.json')){
  if(!(Test-Path -LiteralPath (Join-Path $appDir $file))){throw "Missing file: $file"}
}
$startup=[Environment]::GetFolderPath('Startup')
if(!$startup){throw 'Windows Startup folder unavailable.'}
$shortcut=Join-Path $startup 'GPT Niang Usage.lnk'
$manifest=Get-Content -LiteralPath (Join-Path $appDir '.codex-plugin\plugin.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$config=@{version=$manifest.version;appDir=$appDir;dataDir=$dataDir;nodePath=$node;codexPath=$codex;marketplaceRoot=$marketplaceRoot;startupShortcut=$shortcut;installedAt=[DateTime]::UtcNow.ToString('o')}
if($CheckOnly){@{ok=$true;appDir=$appDir;codex=$codex;startupShortcut=$shortcut}|ConvertTo-Json;return}
$null=New-Item -ItemType Directory -Path $dataDir -Force
if(Test-Path -LiteralPath $shortcut){
  $existing=(New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
  if($existing.Arguments-notlike ('*'+(Join-Path $appDir 'launch.vbs')+'*')){throw 'Existing shortcut belongs to another installation.'}
}
# All plugin files are prepared locally before registration.
[IO.File]::WriteAllText((Join-Path $appDir 'installation.json'),($config|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
. (Join-Path $appDir 'runtime\supervisor-task.ps1')
Stop-WidgetSupervisorTask -AppDir $appDir
# Stop only the recorded GUI belonging to this installation before updating it.
$oldRuntime=$null
try{$oldRuntime=Get-Content -LiteralPath (Join-Path $dataDir 'runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json}catch{}
if($oldRuntime){
  $oldProcess=Get-CimInstance Win32_Process -Filter ('ProcessId='+[int]$oldRuntime.pid) -ErrorAction SilentlyContinue
  $expectedGui='"'+(Join-Path $appDir 'widget.ps1')+'"'
  if($oldProcess -and $oldProcess.Name-eq 'powershell.exe' -and $oldProcess.CommandLine.IndexOf($expectedGui,[StringComparison]::OrdinalIgnoreCase)-ge 0){
    [IO.File]::WriteAllText((Join-Path $dataDir 'stop.flag'),'stop')
    $deadline=[DateTime]::UtcNow.AddSeconds(6)
    while((Get-Process -Id ([int]$oldRuntime.pid) -ErrorAction SilentlyContinue) -and [DateTime]::UtcNow-lt $deadline){Start-Sleep -Milliseconds 100}
    if(Get-Process -Id ([int]$oldRuntime.pid) -ErrorAction SilentlyContinue){throw 'The previous widget did not stop.'}
  }
}
& $codex plugin marketplace add $marketplaceRoot --json
if($LASTEXITCODE-ne 0){throw 'Codex rejected the local marketplace.'}
& $codex plugin add 'gpt-niang-usage@gpt-niang-local' --json
if($LASTEXITCODE-ne 0){throw 'Codex rejected the GPT Niang plugin.'}
$catalog=(& $codex plugin list --json)|ConvertFrom-Json
if($LASTEXITCODE-ne 0){throw 'Cannot verify plugin registration.'}
$match=@($catalog.installed|Where-Object{$_.pluginId-eq 'gpt-niang-usage@gpt-niang-local' -and $_.version-eq $manifest.version -and $_.installed -and $_.enabled})
if($match.Count-ne 1){throw 'Codex did not report one enabled GPT Niang plugin.'}
$shell=New-Object -ComObject WScript.Shell
$link=$shell.CreateShortcut($shortcut)
$link.TargetPath=Join-Path $env:WINDIR 'System32\wscript.exe'
$link.Arguments='"'+(Join-Path $appDir 'launch.vbs')+'"'
$link.WorkingDirectory=$appDir
$link.Description='GPT Niang: Codex subscription quota widget'
$link.Save()
$task=Register-WidgetSupervisorTask -AppDir $appDir
Write-Output ('GPT Niang '+$manifest.version+' registered; supervisor started: '+$task.TaskName)
