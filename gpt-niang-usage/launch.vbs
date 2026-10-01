Option Explicit
Dim widgetShell, widgetFiles, widgetRoot, widgetCommand
Set widgetShell = CreateObject("WScript.Shell")
Set widgetFiles = CreateObject("Scripting.FileSystemObject")
widgetRoot = widgetFiles.GetParentFolderName(WScript.ScriptFullName)
widgetCommand = "powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & widgetRoot & "\runtime\start-supervisor.ps1"""
widgetShell.Run widgetCommand, 0, False
