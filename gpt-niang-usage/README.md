# GPT娘额度挂件

这是项目的插件与桌面挂件目录。安装、使用、更新和隐私说明请看[项目主页](../README.md)。

- `Install.ps1`：检查依赖并安装；`-CheckOnly` 只检查，不修改系统。
- `widget.ps1` / `widget.xaml`：Windows WPF 挂件与界面。
- `runtime/mcp.mjs`：只读额度查询工具。
- `runtime/supervisor.ps1`：识别主窗口并自动恢复角色。
- `runtime/host-layer.ps1`：主窗口归属与遮挡顺序。
- `assets/quotes.json`：内置中文语录。
- `tests/`：额度解析与刷新队列测试。

`installation.json` 在本机安装时生成，不包含在仓库中。默认个人数据位于 `%LOCALAPPDATA%\GPTNiangUsage\state`，停用后保留。

额度气泡在原有尺寸内显示剩余百分比、进度条和重置时间。展开动画结束后，前 2 秒显示距离重置多久，后 3 秒显示固定日期和重置时刻，然后自动收起；再次点击角色或刷新时重新计时。重置时刻、今日／明日及更新时间均按当前 Windows 机器的本地时间显示；悬停气泡可查看完整日期、时区偏移与倒计时。缺少重置时间时会明确提示，过期的额度等待刷新。

交互实现范围见[DSH功能对照](DSH功能对照.md)，图片生成来源见[素材说明](assets/生成说明.md)。
