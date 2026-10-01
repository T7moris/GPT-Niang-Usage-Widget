# 参与 GPT娘额度挂件

感谢帮龙娘变得更好。问题和建议请使用中文或清晰的英文描述。

## 本地检查

需要 Windows 10 / 11、Windows PowerShell 5.1，以及 Node.js 20 或更新版本。不需要安装 npm 依赖。

```powershell
cd gpt-niang-usage
node --test tests/*.test.mjs
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -CheckOnly
```

`-CheckOnly` 只检查安装条件。实际运行安装器会登记本地插件和当前用户自动启动任务，调试前请了解自己的安装目录，避免同时安装多个副本。

## 修改时注意

- `*.ps1` 保留 UTF-8 BOM，保证 Windows PowerShell 5.1 正确读取中文。
- 额度来自服务端的使用百分比；界面显示的是剩余额度。缺失窗口和过期快照不能显示为满额。
- 窗口变化需验证：主窗口、最小化、被其他应用覆盖、重开客户端、仅打开 mini 宠物窗。
- 不提交本机的 `installation.json`、状态文件、凭据、个人对话截图或运行日志。
- 图像与音效请说明来源；代码 MIT 许可不代表第三方角色或商标也采用 MIT 许可。

提交 PR 时写清问题、改动后的行为、已验证内容和仍有限制的情况。界面变化附上不含私人信息的截图即可。
