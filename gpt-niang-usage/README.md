# GPT娘额度挂件

这是项目的插件与桌面挂件目录。安装、使用、更新和隐私说明请看[项目主页](../README.md)。

- `Install.ps1`：检查依赖并安装；`-CheckOnly` 只检查，不修改系统。
- `widget.ps1` / `widget.xaml`：Windows WPF 挂件与界面。
- `runtime/mcp.mjs`：只读额度查询工具。
- `runtime/watch.mjs`：后台额度进程，统一处理刷新请求并保存当前账号的额度快照。
- `runtime/supervisor.ps1`：识别主窗口并自动恢复角色。
- `runtime/host-layer.ps1`：主窗口归属与遮挡顺序。
- `assets/quotes.json`：内置中文语录。
- `tests/`：额度解析、账号快照隔离、刷新并发，以及 Windows 安装、进程恢复与界面测试。

`installation.json` 在本机安装时生成，不包含在仓库中。默认个人数据位于 `%LOCALAPPDATA%\GPTNiangUsage\state`，停用后保留。

只读取 Codex 当前登录的账号；不提供账号切换、账号列表或同时查询多个账号的功能。

交互实现范围见[DSH功能对照](DSH功能对照.md)，图片生成来源见[素材说明](assets/生成说明.md)。
