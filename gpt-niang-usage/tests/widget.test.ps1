param([string]$PreviewDirectory,[string]$TestRoot=$PSScriptRoot)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
$appDir=Split-Path $TestRoot -Parent
. ([ScriptBlock]::Create([IO.File]::ReadAllText((Join-Path $appDir 'runtime\quote-layout.ps1'),[Text.Encoding]::UTF8)))
Initialize-WidgetQuoteLayouts $appDir
$tokens=$null;$parseErrors=$null
$source=[IO.File]::ReadAllText((Join-Path $appDir 'widget.ps1'),[Text.Encoding]::UTF8)
$ast=[Management.Automation.Language.Parser]::ParseInput($source,[ref]$tokens,[ref]$parseErrors)
if($parseErrors.Count){throw ($parseErrors|Out-String)}
foreach($name in @('Reset-Label','Format-ResetTime','Format-ResetDisplay','Get-QuotaWindowLabel','Get-QuotaRows','Set-ResetTimeMode','Restart-SceneTtl','Tick-Scene','Apply-Scene','Update-BubbleTooltip','Update-Quota')){
  $definition=$ast.Find({param($node)$node-is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name-eq $name},$true)
  . ([ScriptBlock]::Create($definition.Extent.Text))
}
function Assert-Equal($actual,$expected,[string]$message){if($actual-ne $expected){throw "$message : expected '$expected', got '$actual'"}}
$script:dataDir=Join-Path ([IO.Path]::GetTempPath()) ('gpt-niang-widget-test-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $script:dataDir
$script:window=[Windows.Markup.XamlReader]::Parse([IO.File]::ReadAllText((Join-Path $appDir 'widget.xaml'),[Text.Encoding]::UTF8))
$script:ui=@{}
foreach($name in @('Root','Girl','Bubble','SceneText','QuotaText','Refresh','ShortRow','WeekRow','ShortLabel','WeekLabel','ShortUsed','ShortLeft','ShortReset','ShortBar','WeekUsed','WeekLeft','WeekReset','WeekBar','Status','LiveDot','Header','QuoteText')){$script:ui[$name]=$script:window.FindName($name)}
$script:ui.Girl.Source=[Windows.Media.Imaging.BitmapImage]::new([Uri](Join-Path $appDir 'assets\gpt-dragon-niang-bust.png'))
$script:bubbleMode='quota';$script:status=$null;$script:statusStamp=0
$script:resetTimeMode='fixed';$script:resetPhaseTimer=$null;$script:collapsed=$true;$script:closeCount=0
function Hide-Quota {
  $script:collapsed=$true;$script:sceneDeadline=0;$script:closeCount++
  if($script:resetPhaseTimer){$script:resetPhaseTimer.Stop();$script:resetPhaseTimer=$null}
}
$now=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$short=@{minutes=300;used=25;remaining=75;resetsAt=[Math]::Floor($now/1000)+3600}
$week=@{minutes=10080;used=10;remaining=90;resetsAt=[Math]::Floor($now/1000)+345600}
function Set-Snapshot($snapshot){
  [IO.File]::WriteAllText((Join-Path $script:dataDir 'status.json'),($snapshot|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
  $script:statusStamp=0;Update-Quota
}
function Save-Preview([string]$name,[double]$scale=1){
  if(!$PreviewDirectory){return}
  $null=New-Item -ItemType Directory -Path $PreviewDirectory -Force
  $size=[int][Math]::Round(350*$scale);$viewport=$script:window.Content
  $viewport.Measure([Windows.Size]::new($size,$size));$viewport.Arrange([Windows.Rect]::new(0,0,$size,$size));$viewport.UpdateLayout()
  $render=[Windows.Media.Imaging.RenderTargetBitmap]::new($size,$size,96,96,[Windows.Media.PixelFormats]::Pbgra32)
  $render.Render($viewport);$encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new()
  $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($render))
  $stream=[IO.File]::Create((Join-Path $PreviewDirectory ($name+'.png')))
  try{$encoder.Save($stream)}finally{$stream.Dispose()}
}
function Assert-QuotaLayout {
  $scene=$script:window.FindName('SceneText');$root=$script:ui.Root
  $root.Measure([Windows.Size]::new(350,350));$root.Arrange([Windows.Rect]::new(0,0,350,350));$root.UpdateLayout()
  foreach($prefix in @('Short','Week')){
    if($script:ui[$prefix+'Row'].Visibility-eq [Windows.Visibility]::Collapsed){continue}
    foreach($suffix in @('Left','Reset','Bar')){
      $control=$script:ui[$prefix+$suffix];$origin=$control.TranslatePoint([Windows.Point]::new(0,0),$scene)
      if($origin.X-lt -0.5 -or $origin.Y-lt -0.5 -or $origin.X+$control.ActualWidth-gt $scene.ActualWidth+0.5 -or $origin.Y+$control.ActualHeight-gt $scene.ActualHeight+0.5){throw "$prefix$suffix escapes the bubble text area"}
    }
    $reset=$script:ui[$prefix+'Reset']
    if($reset.Visibility-ne [Windows.Visibility]::Visible -or $reset.FontSize-lt 12){throw 'Reset time must be visible and readable'}
    $typeface=[Windows.Media.Typeface]::new($reset.FontFamily,$reset.FontStyle,$reset.FontWeight,$reset.FontStretch)
    $formatted=[Windows.Media.FormattedText]::new($reset.Text,[Globalization.CultureInfo]::InvariantCulture,[Windows.FlowDirection]::LeftToRight,$typeface,$reset.FontSize,$reset.Foreground)
    if($formatted.Width-gt $reset.ActualWidth){throw "Reset time is horizontally clipped: $($reset.Text)"}
    $bottom=$reset.TranslatePoint([Windows.Point]::new(0,$reset.ActualHeight),$root).Y
    if($bottom-gt [Windows.Controls.Canvas]::GetTop($script:ui.Girl)-2){throw 'Reset time overlaps the character'}
  }
}
try{
  $localClock=[DateTime]::new(2026,10,5,23,30,0)
  $clock=[DateTimeOffset]::new($localClock,[TimeZoneInfo]::Local.GetUtcOffset($localClock)).ToUnixTimeSeconds()
  Assert-Equal (Format-ResetTime ($clock+1200) $clock) '今日 23:50 重置' 'Machine-local same-day reset'
  Assert-Equal (Format-ResetTime ($clock+2400) $clock) '明日 00:10 重置' 'Machine-local midnight boundary'
  $localWeek=[DateTime]::new(2026,10,12,12,0,0)
  $weeklyTimestamp=[DateTimeOffset]::new($localWeek,[TimeZoneInfo]::Local.GetUtcOffset($localWeek)).ToUnixTimeSeconds()
  Assert-Equal (Format-ResetTime $weeklyTimestamp $clock) '10-12 12:00 重置' 'Weekly reset includes local date'
  Assert-Equal (Format-ResetTime $clock $clock) '重置已到，等待更新' 'Reached reset waits for new snapshot'
  $utcClock=[DateTimeOffset]::Parse('2026-10-05T23:30:00Z').ToUnixTimeSeconds()
  $utcReset=[DateTimeOffset]::Parse('2026-10-06T00:10:00Z').ToUnixTimeSeconds()
  foreach($case in @(
    @{id='UTC';expected='明日 00:10 重置'},
    @{id='China Standard Time';expected='今日 08:10 重置'},
    @{id='Eastern Standard Time';expected='今日 20:10 重置'},
    @{id='Nepal Standard Time';expected='今日 05:55 重置'},
    @{id='Line Islands Standard Time';expected='今日 14:10 重置'}
  )){
    $zone=[TimeZoneInfo]::FindSystemTimeZoneById($case.id)
    Assert-Equal (Format-ResetTime $utcReset $utcClock $zone) $case.expected ('Local date in '+$case.id)
  }
  $springClock=[DateTimeOffset]::Parse('2026-03-08T05:30:00Z').ToUnixTimeSeconds()
  $springReset=[DateTimeOffset]::Parse('2026-03-08T08:30:00Z').ToUnixTimeSeconds()
  Assert-Equal (Format-ResetTime $springReset $springClock ([TimeZoneInfo]::FindSystemTimeZoneById('Eastern Standard Time'))) '今日 04:30 重置' 'Daylight saving uses the reset date offset'
  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($short,$week)}
  Apply-Scene
  Assert-Equal $script:ui.LiveDot.Visibility Collapsed 'Header status dot stays hidden when quota bubble opens'
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
  Assert-QuotaLayout
  if(!$script:bubbleTooltipText.Text.Contains('本机时间')){throw 'Exact local reset timezone missing from tooltip'}
  $shortLocal=[DateTimeOffset]::FromUnixTimeSeconds([long]$short.resetsAt).ToLocalTime().ToString('yyyy-MM-dd HH:mm zzz')
  if(!$script:bubbleTooltipText.Text.Contains($shortLocal)){throw 'Tooltip does not use the machine timezone'}
  Save-Preview 'both-windows'
  Save-Preview 'both-windows-large' 2
  foreach($scale in @(0.6,1,1.4,2.5)){Save-Preview ('scale-'+$scale) $scale}
  $script:window.FindName('FacingScale').ScaleX=-1;$script:window.FindName('TextFacingScale').ScaleX=-1
  Save-Preview 'both-windows-left'
  $script:window.FindName('FacingScale').ScaleX=1;$script:window.FindName('TextFacingScale').ScaleX=1

  $script:collapsed=$false
  Restart-SceneTtl 0 $now
  Assert-Equal $script:sceneDeadline ($now+5000) 'Original five-second display is retained'
  Assert-Equal $script:resetTimeMode countdown 'Opening begins with relative time'
  Assert-Equal $script:ui.ShortReset.Text (Reset-Label ($short.resetsAt-[Math]::Floor($now/1000))) 'First half shows countdown'
  Assert-QuotaLayout;Save-Preview 'first-half-countdown'
  Tick-Scene ($now+1999)
  Assert-Equal $script:resetTimeMode countdown 'Countdown remains just before midpoint'
  Tick-Scene ($now+2000)
  Assert-Equal $script:resetTimeMode fixed 'Both rows switch at midpoint'
  Assert-Equal $script:ui.ShortReset.Text (Format-ResetTime $short.resetsAt ([Math]::Floor(($now+2000)/1000))) 'Last three seconds show local reset time'
  Assert-Equal $script:ui.WeekReset.Text (Format-ResetTime $week.resetsAt ([Math]::Floor(($now+2000)/1000))) 'Weekly row switches together'
  Update-Quota
  Assert-Equal $script:resetTimeMode fixed 'Quota refresh does not reset phase'
  Assert-Equal $script:ui.ShortLeft.Text '75%' 'Phase switch keeps quota percentage'
  Assert-Equal $script:ui.ShortBar.Width 138 'Phase switch keeps quota bar'
  Assert-QuotaLayout;Save-Preview 'second-half-fixed'
  Tick-Scene ($now+4999)
  Assert-Equal $script:collapsed $false 'Second half stays visible until deadline'
  Tick-Scene ($now+5000)
  Assert-Equal $script:collapsed $true 'Bubble closes at original deadline'
  Tick-Scene ($now+5001)
  Assert-Equal $script:closeCount 1 'Deadline closes once'

  $script:collapsed=$false
  Restart-SceneTtl 520 $now
  Assert-Equal $script:sceneStartedAt ($now+520) 'Opening animation is excluded from readable time'
  Tick-Scene ($now+2519)
  Assert-Equal $script:resetTimeMode countdown 'Opening delay preserves entire first half'
  Tick-Scene ($now+2520)
  Assert-Equal $script:resetTimeMode fixed 'Midpoint follows opening animation'
  $oldPhaseTimer=$script:resetPhaseTimer
  Restart-SceneTtl 0 ($now+3500)
  Assert-Equal $oldPhaseTimer.IsEnabled $false 'Restart cancels old phase timer'
  Assert-Equal $script:resetTimeMode countdown 'Reopening or refresh restarts countdown'
  Tick-Scene ($now+5499)
  Assert-Equal $script:resetTimeMode countdown 'Restart preserves two new seconds of countdown'
  Tick-Scene ($now+5520)
  Assert-Equal $script:collapsed $false 'Old deadline cannot close refreshed bubble'
  Assert-Equal $script:resetTimeMode fixed 'New midpoint follows restarted scene'
  $script:bubbleMode='quote'
  Restart-SceneTtl 0 $now
  Assert-Equal $script:resetPhaseTimer $null 'Quote scene has no quota phase timer'
  Tick-Scene ($now+2000)
  Assert-Equal $script:resetTimeMode countdown 'Quote scene cannot switch quota reset labels'
  $script:bubbleMode='quota'

  # Exercise the actual WPF timer; do not change production state or system time.
  Restart-SceneTtl
  $frame=[Windows.Threading.DispatcherFrame]::new()
  $finishTimer=[Windows.Threading.DispatcherTimer]::new()
  $finishTimer.Interval=[TimeSpan]::FromMilliseconds(2300)
  $finishTimer.Add_Tick({param($timer,$event)$timer.Stop();$frame.Continue=$false})
  $finishTimer.Start()
  [Windows.Threading.Dispatcher]::PushFrame($frame)
  Assert-Equal $script:resetTimeMode fixed 'Native WPF timer switches without quota polling'
  Assert-Equal $script:resetPhaseTimer.IsEnabled $true 'Phase timer reserves three seconds for the date'
  $nativePhaseTimer=$script:resetPhaseTimer
  $frame=[Windows.Threading.DispatcherFrame]::new()
  $finishTimer.Interval=[TimeSpan]::FromMilliseconds(2950)
  $finishTimer.Start()
  [Windows.Threading.Dispatcher]::PushFrame($frame)
  Assert-Equal $script:collapsed $true 'Native timer automatically closes at the five-second deadline'
  Assert-Equal $nativePhaseTimer.IsEnabled $false 'Closing stops the phase timer'

  foreach($seconds in @(1,3540,3599,86399,604799)){
    $edge=@{minutes=300;used=25;remaining=75;resetsAt=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()+$seconds}
    $script:resetTimeMode='countdown'
    Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($edge,$week)}
    Assert-QuotaLayout
  }
  $script:resetTimeMode='fixed'

  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($week)}
  Assert-Equal $script:ui.ShortRow.Visibility Collapsed 'Successful absent short window collapses entire row'
  Assert-Equal $script:ui.WeekRow.Visibility Visible 'Week remains visible'
  Assert-Equal $script:ui.WeekRow.Margin.Top 1 'Single row spacing'
  Assert-QuotaLayout
  if($script:bubbleTooltipText.Text.Contains('5 小时')){throw 'Hidden window leaked into tooltip'}
  Save-Preview 'week-only'

  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($short)}
  Assert-Equal $script:ui.WeekRow.Visibility Collapsed 'Successful absent week window collapses entire row'

  $unknownReset=@{minutes=300;used=25;remaining=75;resetsAt=$null}
  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($unknownReset)}
  Assert-Equal $script:ui.ShortLeft.Text '75%' 'Missing reset keeps percentage'
  Assert-Equal $script:ui.ShortReset.Text '未提供重置时间' 'Missing reset label'
  Assert-Equal $script:ui.ShortReset.ToolTip $null 'Old reset tooltip is cleared'
  Assert-QuotaLayout
  Save-Preview 'missing-reset'

  Set-Snapshot @{ok=$true;queryOk=$false;observedAt=$now;error='查询超时';windows=@($week)}
  Assert-Equal $script:ui.ShortRow.Visibility Visible 'Failure never infers unsupported window'
  Assert-Equal $script:ui.WeekLeft.Text '90%' 'Same-account stale snapshot stays visible'
  Assert-Equal $script:ui.Header.Text '上次剩余额度' 'Cached data is labelled as previous'
  Assert-QuotaLayout

  Set-Snapshot @{ok=$false;queryOk=$false;error='请重新登录';windows=@()}
  Assert-Equal $script:ui.ShortLeft.Text '—' 'Account change clears percentage'
  Assert-Equal $script:ui.ShortReset.Text '额度读取异常' 'Failure is distinct from absent window'
  Assert-Equal $script:ui.ShortRow.Visibility Visible 'Error short row visible'
  Assert-Equal $script:ui.Status.Text '请重新登录' 'Error status retained'
  Assert-QuotaLayout
  Save-Preview 'query-error'

  $expired=@{minutes=300;used=25;remaining=75;resetsAt=[Math]::Floor($now/1000)-60}
  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($expired)}
  Assert-Equal $script:ui.ShortLeft.Text '—' 'Expired quota is not shown as live remaining'
  Assert-Equal $script:ui.ShortBar.Width 0 'Expired remaining bar is empty'
  Assert-QuotaLayout
  Save-Preview 'expired-reset'

  foreach($remaining in @(0,0.1,99.9,100)){
    $edge=@{minutes=300;used=100-$remaining;remaining=$remaining;resetsAt=$short.resetsAt}
    Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;windows=@($edge,$week)}
    Assert-QuotaLayout
  }

  foreach($single in @(
    @{minutes=43200;used=12;remaining=88;resetsAt=[Math]::Floor($now/1000)+2592000;label='30 天'},
    @{minutes=1440;used=80;remaining=20;resetsAt=$null;label='1 天'},
    @{minutes=75;used=0;remaining=100;resetsAt=$null;label='75 分钟'}
  )){
    Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;planLabel='Go';windows=@($single)}
    Assert-Equal $script:ui.ShortLabel.Text $single.label 'Generic duration label'
    Assert-Equal $script:ui.ShortLeft.Text ($single.remaining.ToString()+'%') 'Generic duration percentage'
    Assert-Equal $script:ui.WeekRow.Visibility Collapsed 'One actual window hides the unused row'
    Assert-QuotaLayout
    $scene=$script:ui.SceneText;$quota=$script:ui.QuotaText
    $origin=$quota.TranslatePoint([Windows.Point]::new(0,0),$scene)
    if([Math]::Abs($origin.Y+$quota.ActualHeight/2-$scene.ActualHeight/2)-gt 0.5){throw 'Single-window quota content is not vertically centered'}
    if(!$script:bubbleTooltipText.Text.Contains('当前套餐：Go')){throw 'Plan metadata missing from tooltip'}
    Save-Preview ('single-'+$single.minutes)
  }
  Set-Snapshot @{ok=$true;queryOk=$true;observedAt=$now;planLabel='Pro';windows=@(@{minutes=60;used=95;remaining=5;resetsAt=$null},@{minutes=43200;used=20;remaining=80;resetsAt=$null})}
  Assert-Equal $script:ui.ShortLabel.Text '1 小时' 'First generic row'
  Assert-Equal $script:ui.WeekLabel.Text '30 天' 'Second generic row'
  Assert-QuotaLayout
  Save-Preview 'pro-generic-two-windows'
  Remove-Item -LiteralPath (Join-Path $script:dataDir 'status.json')
  Update-Quota
  Assert-Equal $script:status $null 'Removed snapshot is cleared'
  Assert-Equal $script:ui.ShortRow.Visibility Visible 'Loading is not treated as unsupported'
  Write-Output 'PASS: two reset phases, native midpoint timer, restart and close timing, local dates, five timezones, daylight saving, layout and quota edge cases'
}finally{
  foreach($timer in @($script:resetPhaseTimer,$finishTimer)){if($timer){$timer.Stop()}}
  $script:window.Close()
  if([IO.Path]::GetFullPath($script:dataDir).StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)){
    Remove-Item -LiteralPath $script:dataDir -Recurse -Force
  }
}
