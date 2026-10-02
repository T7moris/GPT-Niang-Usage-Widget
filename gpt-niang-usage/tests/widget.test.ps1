param([string]$PreviewDirectory,[string]$TestRoot=$PSScriptRoot)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
$appDir=Split-Path $TestRoot -Parent
$tokens=$null;$parseErrors=$null
$source=[IO.File]::ReadAllText((Join-Path $appDir 'widget.ps1'),[Text.Encoding]::UTF8)
$ast=[Management.Automation.Language.Parser]::ParseInput($source,[ref]$tokens,[ref]$parseErrors)
if($parseErrors.Count){throw ($parseErrors|Out-String)}
foreach($name in @('Reset-Label','Update-BubbleTooltip','Update-Quota')){
  $definition=$ast.Find({param($node)$node-is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name-eq $name},$true)
  . ([ScriptBlock]::Create($definition.Extent.Text))
}
function Assert-Equal($actual,$expected,[string]$message){if($actual-ne $expected){throw "$message : expected '$expected', got '$actual'"}}
$script:dataDir=Join-Path ([IO.Path]::GetTempPath()) ('gpt-niang-widget-test-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $script:dataDir
$script:window=[Windows.Markup.XamlReader]::Parse([IO.File]::ReadAllText((Join-Path $appDir 'widget.xaml'),[Text.Encoding]::UTF8))
$script:ui=@{}
foreach($name in @('Root','Girl','Bubble','ShortRow','WeekRow','ShortUsed','ShortLeft','ShortReset','ShortBar','WeekUsed','WeekLeft','WeekReset','WeekBar','Status','LiveDot','Header','QuoteText')){$script:ui[$name]=$script:window.FindName($name)}
$script:ui.Girl.Source=[Windows.Media.Imaging.BitmapImage]::new([Uri](Join-Path $appDir 'assets\gpt-dragon-niang-bust.png'))
$script:bubbleMode='quota';$script:status=$null;$script:statusStamp=0
$now=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$short=@{minutes=300;used=25;remaining=75;resetsAt=[Math]::Floor($now/1000)+3600}
$week=@{minutes=10080;used=10;remaining=90;resetsAt=[Math]::Floor($now/1000)+86400}
function Set-Snapshot($snapshot){
  [IO.File]::WriteAllText((Join-Path $script:dataDir 'status.json'),($snapshot|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
  $script:statusStamp=0;Update-Quota
}
function Save-Preview([string]$name){
  if(!$PreviewDirectory){return}
  $null=New-Item -ItemType Directory -Path $PreviewDirectory -Force
  $root=$script:ui.Root;$root.Measure([Windows.Size]::new(350,350));$root.Arrange([Windows.Rect]::new(0,0,350,350));$root.UpdateLayout()
  $render=[Windows.Media.Imaging.RenderTargetBitmap]::new(350,350,96,96,[Windows.Media.PixelFormats]::Pbgra32)
  $render.Render($root);$encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new()
  $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($render))
  $stream=[IO.File]::Create((Join-Path $PreviewDirectory ($name+'.png')))
  try{$encoder.Save($stream)}finally{$stream.Dispose()}
}
try{
  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($short,$week)}
  Assert-Equal $script:ui.ShortRow.Visibility Visible 'Short window is visible'
  Assert-Equal $script:ui.WeekRow.Visibility Visible 'Week window is visible'
  Assert-Equal $script:ui.ShortLeft.Text '75%' 'Short percentage'
  Assert-Equal $script:ui.ShortBar.Width 138 'Short remaining bar'
  $root=$script:ui.Root;$root.Measure([Windows.Size]::new(350,350));$root.Arrange([Windows.Rect]::new(0,0,350,350));$root.UpdateLayout()
  $shortTrack=$script:ui.ShortBar.Parent;$weekTrack=$script:ui.WeekBar.Parent
  $shortOrigin=$shortTrack.TranslatePoint([Windows.Point]::new(0,0),$root)
  $weekOrigin=$weekTrack.TranslatePoint([Windows.Point]::new(0,0),$root)
  Assert-Equal $shortOrigin.X $weekOrigin.X 'Both progress tracks have the same left edge'
  Assert-Equal $shortTrack.ActualWidth $weekTrack.ActualWidth 'Both progress tracks have the same width'
  if($weekOrigin.Y+$weekTrack.ActualHeight-gt [Windows.Controls.Canvas]::GetTop($script:ui.Girl)){throw 'Week progress track overlaps the character'}
  Save-Preview 'both-windows'
  $script:window.FindName('FacingScale').ScaleX=-1;$script:window.FindName('TextFacingScale').ScaleX=-1
  Save-Preview 'both-windows-left'
  $script:window.FindName('FacingScale').ScaleX=1;$script:window.FindName('TextFacingScale').ScaleX=1

  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($week)}
  Assert-Equal $script:ui.ShortRow.Visibility Collapsed 'Successful absent short window collapses entire row'
  Assert-Equal $script:ui.WeekRow.Visibility Visible 'Week remains visible'
  Assert-Equal $script:ui.WeekRow.Margin.Top 3 'Single row spacing'
  if($script:bubbleTooltipText.Text.Contains('5 小时')){throw 'Hidden window leaked into tooltip'}
  Save-Preview 'week-only'

  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($short)}
  Assert-Equal $script:ui.WeekRow.Visibility Collapsed 'Successful absent week window collapses entire row'

  $unknownReset=@{minutes=300;used=25;remaining=75;resetsAt=$null}
  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($unknownReset)}
  Assert-Equal $script:ui.ShortLeft.Text '75%' 'Missing reset keeps percentage'
  Assert-Equal $script:ui.ShortReset.Text '未提供重置时间' 'Missing reset label'
  Assert-Equal $script:ui.ShortReset.ToolTip $null 'Old reset tooltip is cleared'

  Set-Snapshot @{ok=$true;queryOk=$false;observedAt=$now;error='查询超时';windows=@($week)}
  Assert-Equal $script:ui.ShortRow.Visibility Visible 'Failure never infers unsupported window'
  Assert-Equal $script:ui.WeekLeft.Text '90%' 'Same-account stale snapshot stays visible'
  Assert-Equal $script:ui.Header.Text '上次剩余额度' 'Cached data is labelled as previous'

  Set-Snapshot @{ok=$false;queryOk=$false;error='请重新登录';windows=@()}
  Assert-Equal $script:ui.ShortLeft.Text '—' 'Account change clears percentage'
  Assert-Equal $script:ui.ShortReset.Text '额度读取异常' 'Failure is distinct from absent window'
  Assert-Equal $script:ui.ShortRow.Visibility Visible 'Error short row visible'
  Assert-Equal $script:ui.Status.Text '请重新登录' 'Error status retained'
  Save-Preview 'query-error'

  $expired=@{minutes=300;used=25;remaining=75;resetsAt=[Math]::Floor($now/1000)-60}
  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($expired)}
  Assert-Equal $script:ui.ShortLeft.Text '—' 'Expired quota is not shown as live remaining'
  Assert-Equal $script:ui.ShortBar.Width 0 'Expired remaining bar is empty'

  Remove-Item -LiteralPath (Join-Path $script:dataDir 'status.json')
  Update-Quota
  Assert-Equal $script:status $null 'Removed snapshot is cleared'
  Assert-Equal $script:ui.ShortRow.Visibility Visible 'Loading is not treated as unsupported'
  Write-Output 'PASS: widget quota visibility, errors, missing reset, expiry, tooltip and deleted snapshot'
}finally{
  $script:window.Close()
  if([IO.Path]::GetFullPath($script:dataDir).StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)){
    Remove-Item -LiteralPath $script:dataDir -Recurse -Force
  }
}
