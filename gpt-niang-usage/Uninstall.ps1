$ErrorActionPreference='Stop'
$config=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'installation.json') -Raw -Encoding UTF8|ConvertFrom-Json
. (Join-Path $PSScriptRoot 'runtime\supervisor-task.ps1')
$null=Get-WidgetSupervisorInfo -AppDir $PSScriptRoot -Configuration $config
# Refuse a foreign startup registration before stopping this installation.
if(Test-Path -LiteralPath $config.startupShortcut){
  $link=(New-Object -ComObject WScript.Shell).CreateShortcut($config.startupShortcut)
  if(!(Test-WidgetStartupShortcutIdentity -Shortcut $link -AppDir $PSScriptRoot)){throw 'Startup shortcut identity mismatch.'}
}
$null=Unregister-WidgetSupervisorTask -AppDir $PSScriptRoot
Stop-WidgetGui -AppDir $PSScriptRoot -DataDir $config.dataDir
if(Test-Path -LiteralPath $config.startupShortcut){
  Remove-Item -LiteralPath $config.startupShortcut
}
& $config.codexPath plugin remove 'gpt-niang-usage@gpt-niang-local' --json
if($LASTEXITCODE-ne 0){throw 'Codex plugin removal failed.'}
& $config.codexPath plugin marketplace remove 'gpt-niang-local' --json
if($LASTEXITCODE-ne 0){throw 'Codex marketplace removal failed.'}
$config|Add-Member -NotePropertyName disabledAt -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
Write-WidgetSupervisorJson (Join-Path $PSScriptRoot 'installation.json') $config
Write-Output 'GPT Niang disabled. Source files and preferences were preserved.'
