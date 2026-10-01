$ErrorActionPreference='Stop'
$config=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'installation.json') -Raw -Encoding UTF8|ConvertFrom-Json
. (Join-Path $PSScriptRoot 'runtime\supervisor-task.ps1')
$null=Unregister-WidgetSupervisorTask -AppDir $PSScriptRoot
[IO.File]::WriteAllText((Join-Path $config.dataDir 'stop.flag'),'stop')
if(Test-Path -LiteralPath $config.startupShortcut){
  $link=(New-Object -ComObject WScript.Shell).CreateShortcut($config.startupShortcut)
  if($link.Arguments-like ('*'+(Join-Path $PSScriptRoot 'launch.vbs')+'*')){Remove-Item -LiteralPath $config.startupShortcut}
  else{throw 'Startup shortcut identity mismatch.'}
}
& $config.codexPath plugin remove 'gpt-niang-usage@gpt-niang-local' --json
if($LASTEXITCODE-ne 0){throw 'Codex plugin removal failed.'}
& $config.codexPath plugin marketplace remove 'gpt-niang-local' --json
if($LASTEXITCODE-ne 0){throw 'Codex marketplace removal failed.'}
Write-Output 'GPT Niang disabled. Source files and preferences were preserved.'
