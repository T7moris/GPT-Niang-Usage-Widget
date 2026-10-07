param([switch]$Json)
$ErrorActionPreference='Stop'
$nodeCommand=Get-Command node.exe -ErrorAction SilentlyContinue
$nodePath=if($nodeCommand){$nodeCommand.Source}else{$null}
$configFile=Join-Path $PSScriptRoot 'installation.json'
if(Test-Path -LiteralPath $configFile){
  $config=Get-Content -LiteralPath $configFile -Raw -Encoding UTF8|ConvertFrom-Json
  if(Test-Path -LiteralPath $config.nodePath){$nodePath=$config.nodePath}
}
if(!$nodePath){throw 'Node.js 20 or later is required.'}
$arguments=@((Join-Path $PSScriptRoot 'runtime\detect-plan.mjs'))
if($Json){$arguments+='--json'}
& $nodePath @arguments
exit $LASTEXITCODE
