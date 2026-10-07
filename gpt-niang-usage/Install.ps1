param([switch]$CheckOnly)
$ErrorActionPreference='Stop'
$appDir=$PSScriptRoot
. (Join-Path $appDir 'runtime\supervisor-task.ps1')
$localData=[Environment]::GetFolderPath('LocalApplicationData')
if(!$localData){throw 'Local application data folder unavailable.'}
$dataDir=Join-Path $localData 'GPTNiangUsage\state'
# Preserve an existing installation's chosen data directory on an in-place upgrade.
$previousConfig=Join-Path $appDir 'installation.json'
if(Test-Path -LiteralPath $previousConfig){
  $previous=Get-Content -LiteralPath $previousConfig -Raw -Encoding UTF8|ConvertFrom-Json
  $dataDir=Get-WidgetInstallationDataDir -AppDir $appDir -Configuration $previous
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
foreach($file in @('widget.ps1','widget.xaml','launch.vbs','supervisor.vbs','Detect-Plan.ps1','assets\gpt-dragon-niang-bust.png','assets\quotes.json','assets\quote-layouts.json','assets\press.wav','assets\release.wav','runtime\quotes.ps1','runtime\ui-settings.ps1','runtime\color-theme.ps1','runtime\quote-layout.ps1','runtime\audio.ps1','runtime\host-layer.ps1','runtime\host-follow.ps1','runtime\supervisor.ps1','runtime\supervisor-task.ps1','runtime\start-supervisor.ps1','runtime\start-widget.ps1','runtime\metadata.mjs','runtime\mcp.mjs','runtime\usage.mjs','runtime\plan.mjs','runtime\detect-plan.mjs','runtime\watch.mjs','runtime\control.mjs','runtime\refresh-queue.mjs','runtime\refresh-client.mjs','runtime\worker-state.mjs','.mcp.json','.codex-plugin\plugin.json')){
  if(!(Test-Path -LiteralPath (Join-Path $appDir $file))){throw "Missing file: $file"}
}
$startup=[Environment]::GetFolderPath('Startup')
if(!$startup){throw 'Windows Startup folder unavailable.'}
$shortcut=Join-Path $startup 'GPT Niang Usage.lnk'
$manifest=Get-Content -LiteralPath (Join-Path $appDir '.codex-plugin\plugin.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$config=@{version=$manifest.version;appDir=$appDir;dataDir=$dataDir;nodePath=$node;codexPath=$codex;marketplaceRoot=$marketplaceRoot;startupShortcut=$shortcut;installedAt=[DateTime]::UtcNow.ToString('o')}
# Validate all globally shared registrations before changing local configuration or stopping anything.
$info=Get-WidgetSupervisorInfo -AppDir $appDir -Configuration $config
$null=Get-WidgetSupervisorTask $info
if(Test-Path -LiteralPath $shortcut){
  $existing=(New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
  if(!(Test-WidgetStartupShortcutIdentity -Shortcut $existing -AppDir $appDir)){throw 'Existing shortcut belongs to another installation.'}
}
if($CheckOnly){@{ok=$true;appDir=$appDir;codex=$codex;startupShortcut=$shortcut}|ConvertTo-Json;return}
$null=New-Item -ItemType Directory -Path $dataDir -Force
# All plugin files are prepared locally before registration.
Write-WidgetSupervisorJson (Join-Path $appDir 'installation.json') $config
Stop-WidgetSupervisorTask -AppDir $appDir
Stop-WidgetGui -AppDir $appDir -DataDir $dataDir
& $codex plugin marketplace add $marketplaceRoot --json
if($LASTEXITCODE-ne 0){throw 'Codex rejected the local marketplace.'}
& $codex plugin add 'gpt-niang-usage@gpt-niang-local' --json
if($LASTEXITCODE-ne 0){throw 'Codex rejected the GPT Niang plugin.'}
# Decode the UTF-8 JSON directly, independent of the console code page.
$processInfo=New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName=$codex
$processInfo.Arguments='plugin list --json'
$processInfo.UseShellExecute=$false
$processInfo.RedirectStandardOutput=$true
$processInfo.StandardOutputEncoding=[Text.UTF8Encoding]::new($false)
$process=New-Object System.Diagnostics.Process
$process.StartInfo=$processInfo
try{
  if(!$process.Start()){throw 'Cannot start Codex plugin list.'}
  $catalogJson=$process.StandardOutput.ReadToEnd()
  $process.WaitForExit()
  $exitCode=$process.ExitCode
}finally{$process.Dispose()}
if($exitCode-ne 0){throw 'Cannot verify plugin registration.'}
$catalog=$catalogJson|ConvertFrom-Json
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
