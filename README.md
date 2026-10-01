# GPT娘额度挂件

让一只白发紫瞳的小龙娘，陪你看 Codex 的剩余额度。

**Windows 桌面挂件 · 5 小时 / 每周额度 · 中文语录 · 当前版本 1.2.3**

[**下载最新版**](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest) · [安装方法](#安装) · [更新记录](更新记录.md) · [反馈问题](https://github.com/T7moris/GPT-Niang-Usage-Widget/issues/new/choose)

<img src="gpt-niang-usage/assets/gpt-dragon-niang-bust.png" alt="无嘴巴的白发龙娘半身形象" width="240">

## 能做什么

- **点角色看额度**：显示 5 小时和每周剩余百分比；横条越满，剩余额度越多。
- **点气泡看语录**：再点收起，显示完成约 5 秒后也会自动收起；支持编辑自己的语录。
- **按压与回弹**：半身角色、分段气泡动画和轻提示音，可调整音量或静音。
- **拖动与缩放**：靠近左右边缘吸附，角色面向窗口内侧，文字保持正向。
- **跟随主窗口**：失去焦点时保留；其他窗口覆盖主窗口时，也会覆盖挂件。最小化或隐藏主窗口后挂件隐藏。
- **自动恢复**：当前用户登录后监测主窗口；重开客户端时自动显示。仅打开宠物 mini 不显示。

这是独立的 Windows 本地挂件及额度查询插件。它读取当前 Codex 登录账户的额度，**不会为读取额度创建聊天或调用模型**。它不是 OpenAI 或 DeepSeek 的官方项目。

## 安装

需要 **Windows 10 / 11、Node.js 20 或更新版本，以及已安装并用 ChatGPT 订阅登录的 Codex 桌面端**。

1. 打开 [Release 下载页](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest)，在 **Assets** 中下载 **`GPT娘额度挂件-v1.2.3-Windows.zip`**。也可以使用 **Code → Download ZIP** 获取当前源码。
2. 将压缩包**完整解压**到准备长期保留的位置；保留 `.agents` 与 `gpt-niang-usage` 文件夹。
3. 双击根目录的 **`安装GPT娘.cmd`**，等待安装完成。
4. 打开 Codex 主窗口，龙娘会自动出现。额度查询工具可在新建的聊天中使用。

安装器会查找 Node.js 与 Codex，并注册本地插件及当前用户的自动启动任务。**不需要以管理员身份运行**。若缺少 Node.js，请先从 [Node.js 官方网站](https://nodejs.org/) 安装并重新打开安装器。

## 使用

| 操作 | 效果 |
| --- | --- |
| 点角色 | 查看剩余额度；已在额度页时重新计时 |
| 点额度气泡 | 切换到随机语录 |
| 再点语录气泡 | 收起气泡 |
| 拖动角色 | 调整在主窗口内的位置 |
| 右键角色 | 打开设置，调整大小、声音、语录与位置 |
| 双击 `打开GPT娘.cmd` | 手动恢复显示；重复打开不会叠加第二只 |
| 菜单中选择「退出 GPT 娘」 | 本次主窗口会话中退出，下次重开主窗口恢复 |
| 双击 `停用GPT娘.cmd` | 停用自动显示，移除本项目的任务、启动项与插件登记 |

## 数据与隐私

- 通过本机 Codex App Server 读取登录类型与额度窗口。项目没有自己的云服务器、遥测或外部上传功能。
- 不保存登录凭据、邮箱、对话内容；状态文件仅保存额度数字、时间、显示偏好和运行状态。
- 新安装的偏好和状态保存在 `%LOCALAPPDATA%\GPTNiangUsage\state`，安装路径记录保存在本机生成的 `installation.json`。
- 超过 3 分钟的数据标为旧快照；重置时间已到时，会等待新数据，不擅自把额度补为 100%。
- 使用 API Key 登录、账户没有返回相应窗口，或接口不可用时，无法显示订阅额度。

本仓库不包含作者的本机安装配置、账户快照、个人语录或聊天截图。

## 更新、移动与卸载

在**原目录**覆盖新版文件，再运行 `安装GPT娘.cmd`；安装器会保留原有数据目录和偏好。安装前请先备份自定义内容。

需要移动文件夹时，先在原目录运行 `停用GPT娘.cmd`，再移动并重新安装。停用不会删除偏好；再次安装可继续使用。不要直接移动正在运行的安装目录。

## 常见问题

**看不到角色？** 确认打开的是主窗口而非宠物 mini，主窗口没有最小化；运行 `打开GPT娘.cmd`。如果其他应用盖住了主窗口，挂件会一起被盖住。

**额度数字不更新？** 点击气泡里的刷新按钮，检查 Codex 的 ChatGPT 登录状态；账户没有提供的窗口显示 `—`。

**旧安装占用了自动启动任务？** 先从旧目录运行停用脚本，再安装新版。安装器会拒绝覆盖不属于当前目录的启动项。

**系统或企业策略阻止脚本？** 此版本依赖 Windows PowerShell / WPF、Windows Script Host 和当前用户计划任务。请遵循设备管理策略；项目不会修改系统安全策略。

## 开发与验证

无需安装 npm 依赖。运行额度与刷新测试：

```powershell
cd gpt-niang-usage
node --test tests/*.test.mjs
```

只检查安装条件，不创建任务、不安装插件：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\gpt-niang-usage\Install.ps1 -CheckOnly
```

界面实现为 Windows PowerShell / WPF，额度查询和 MCP 服务使用 Node.js。窗口识别与接口依赖当前 Codex 桌面端实现，后续客户端更新可能需要适配。当前支持 Windows，未提供 macOS / Linux 版本。

## 反馈与参与

遇到问题可以 [提交中文问题反馈](https://github.com/T7moris/GPT-Niang-Usage-Widget/issues/new/choose)。请说明 Windows / Codex / 挂件版本、复现步骤以及期望效果；截图请裁去对话、账号和其他私人信息。不要上传登录文件或整个状态目录。

欢迎改进窗口兼容性、安装流程和可读性。提交代码前请阅读 [贡献说明](CONTRIBUTING.md)，并运行上面的检查。这个版本的角色是静态半身配合按压动画；不包含完整桌宠动作或 macOS / Linux 支持。

## 致谢与许可

交互参考 [DeepSeek-Balance-Whale-Widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget)，本项目采用单独实现的 WPF 界面、原创语录及合成提示音，没有打包 DSH 原角色、动图或音效。具体对照见 [功能对照](gpt-niang-usage/DSH功能对照.md)。

代码采用 [MIT License](LICENSE)。龙娘图由 ImageGen 根据用户提供的角色参考生成；参考角色及相关形象权利仍归相应权利人，代码许可不构成对第三方角色或商标的授权。详见 [素材说明](gpt-niang-usage/assets/生成说明.md)。
