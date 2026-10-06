# GPT娘额度挂件

让一只白发紫瞳的小龙娘，陪你看 Codex 的剩余额度。

**Windows 桌面挂件 · 5 小时 / 每周额度 · 中文语录 · 当前版本 1.2.5**

[**下载最新版**](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest) · [安装方法](#安装) · [更新记录](更新记录.md) · [反馈问题](https://github.com/T7moris/GPT-Niang-Usage-Widget/issues/new)

<img src="gpt-niang-usage/assets/gpt-dragon-niang-bust.png" alt="无嘴巴的白发龙娘半身形象" width="240">

## 能做什么

- **点角色看额度**：按接口实际返回的窗口显示 5 小时或每周剩余百分比；横条越满，剩余额度越多。成功查询时折叠未返回的整条窗口；查询失败会显示异常，重置时间为空时仍保留百分比。
- **点气泡看语录**：再点收起，显示完成约 5 秒后也会自动收起；支持编辑自己的语录。
- **按压与回弹**：半身角色、分段气泡动画和轻提示音，可调整音量或静音。
- **拖动与缩放**：靠近左右边缘吸附，角色面向窗口内侧，文字保持正向。
- **跟随主窗口**：失去焦点时保留；其他窗口覆盖主窗口时，也会覆盖挂件。最小化或隐藏主窗口后挂件隐藏。
- **自动恢复**：当前用户登录后监测主窗口；重开客户端时自动显示。仅打开宠物 mini 不显示。

这是独立的 Windows 本地挂件及额度查询插件。它读取当前 Codex 登录账户的额度，**不会为读取额度创建聊天或调用模型**。它不是 OpenAI 或 DeepSeek 的官方项目。

## macOS 原生版本

本仓库新增 SwiftUI / AppKit 的 macOS companion，保留原角色、原版按压回弹、分段气泡、语录淡入、流光配色与音效。支持拖动吸附、双击／右键设置、菜单栏和可选登录启动，并提供独立的聊天速度面板。需要 macOS 13+、Node.js 20+ 和已登录的 Codex 桌面端。

从源码运行 `./script/build_and_run.sh`，生成 `dist/GPTNiangMac.app`。完整安装、功能、速度指标解释和验证方式见 [macOS 使用说明](macos/README.md)。原有 Windows Release 安装包仍按下面的方法使用。

## 安装

需要 **Windows 10 / 11、Node.js 20 或更新版本，以及已安装并用 ChatGPT 订阅登录的 Codex 桌面端**。

1. 打开 [Release 下载页](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest)，在 **Assets** 中下载 **`gpt-niang-usage-widget-v1.2.5-windows.zip`**。也可以使用 **Code → Download ZIP** 获取当前源码。
2. 将压缩包**完整解压**到准备长期保留的位置；保留 `.agents` 与 `gpt-niang-usage` 文件夹。
3. 双击根目录的 **`安装GPT娘.cmd`**，等待安装完成。
4. 打开 Codex 主窗口，龙娘会自动出现。额度查询工具可在新建的聊天中使用。

安装器会查找 Node.js 与 Codex，并注册本地插件及当前用户的自动启动任务。**不需要以管理员身份运行**。若缺少 Node.js，请先从 [Node.js 官方网站](https://nodejs.org/) 安装并重新打开安装器。

安装会在本机做这些事：向 Codex 注册一个**本地路径插件市场**及其中的额度插件（内含一个只读的额度查询工具）、在当前用户的启动文件夹创建快捷方式、注册一个**登录时自动启动**的用户级计划任务，并把偏好与额度快照写进 `%LOCALAPPDATA%\GPTNiangUsage\state`。它不写注册表、不安装系统服务、不修改系统安全策略。

### 安装包校验（建议）

本版 `gpt-niang-usage-widget-v1.2.5-windows.zip` 的 SHA256 见同一 [Release 下载页](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/tag/v1.2.5) 的 **`SHA256SUMS.txt`**。下载压缩包和校验文件后，确认计算出的哈希与文件中对应的一行一致。

在 PowerShell 中核对：

```powershell
Get-FileHash .\gpt-niang-usage-widget-v1.2.5-windows.zip -Algorithm SHA256
```

哈希不一致说明文件在传输或转载中被替换，请不要安装。请只从本仓库的 Release 页面下载；第三方加速镜像只用于加速，不能当作可信来源。

## 让 AI 帮你装

把下面这段发给任意能在你电脑上执行命令的 AI：

> 下载 https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest 里的
> `gpt-niang-usage-widget-*-windows.zip`，完整解压到一个长期保留的位置
> （例如 `%LOCALAPPDATA%\Programs\GPTNiangUsage`），然后运行解压目录里的
> `安装GPT娘.cmd`，告诉我结果。

前置条件：Windows 10 / 11、Node.js 20 或更新版本、已安装并用 ChatGPT 订阅登录的 Codex 桌面端。安装器注册的是**本地路径**插件市场，因此**不需要管理员权限，也不需要 git**。

这段提示会让 AI 下载并执行安装脚本。请要求它先核对 Release 中的 SHA256 校验文件、确认下载来源是本仓库的 Release 页面；不要让无法核对来源的自动化流程直接安装。

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
| 双击 `停用GPT娘.cmd` | 停用自动显示，移除本项目的任务、启动项与插件登记（不删除程序文件与偏好，见「彻底移除」） |

## 数据与隐私

- 通过本机 Codex App Server 读取登录类型与额度窗口。项目没有自己的云服务器、遥测或外部上传功能。
- 不保存登录凭据、邮箱、对话内容；状态文件保存额度数字、时间、显示偏好、运行状态，以及用于隔离账号快照的身份哈希。无法确认当前账号时清空旧额度；已确认同账号的刷新失败会明确标记旧快照。
- 当前接口仅公开邮箱和套餐，无法可靠区分同邮箱、同套餐下的组织切换；切换组织后应手动刷新额度。
- 新安装的偏好和状态保存在 `%LOCALAPPDATA%\GPTNiangUsage\state`，安装路径记录保存在本机生成的 `installation.json`。
- 超过 3 分钟的数据标为旧快照；重置时间已到时，会等待新数据，不擅自把额度补为 100%。
- 使用 API Key 登录或接口不可用时显示读取异常；成功查询但没有相应额度窗口时折叠该窗口，不根据套餐名称猜测支持情况。
- 界面、MCP 与控制命令共用单实例额度 worker，状态文件由它统一写入。后台额度查询每 60 秒一次，隐藏时暂停；窗口位置由事件更新，并以每秒一次检测兜底，worker 异常退出后自动恢复。
- 挂件按设计常驻：登录后由用户级计划任务启动一个隐藏的守护进程，用于在 Codex 主窗口出现时显示挂件。在任务管理器里结束挂件进程会被守护自动恢复，这是预期行为；要退出请双击 `停用GPT娘.cmd`。

本仓库不包含作者的本机安装配置、账户快照、个人语录或聊天截图。

## 更新、移动与卸载

在**原目录**覆盖新版文件，再运行 `安装GPT娘.cmd`；安装器会保留原有数据目录和偏好。安装前请先备份自定义内容。

需要移动文件夹时，先在原目录运行 `停用GPT娘.cmd`，等待停用完成，再移动并重新安装。安装器允许已停用、旧路径已不存在的目录迁移，并保留原数据目录与偏好。复制仍存在的旧安装目录或直接移动运行中的目录会被拒绝。

**彻底移除（三步）**：`停用GPT娘.cmd` 会移除计划任务、启动文件夹快捷方式、插件与市场登记并停止进程，但按设计**保留**程序文件与偏好数据。要完全清干净请再手动删除：

1. 双击 `停用GPT娘.cmd`；
2. 删除解压出来的整个程序目录；
3. 删除 `%LOCALAPPDATA%\GPTNiangUsage`（内含偏好、自定义语录和额度快照，不含登录凭据）。

停用脚本在偏好数据目录已被删除时也能完成停用。

## 常见问题

**看不到角色？** 确认打开的是主窗口而非宠物 mini，主窗口没有最小化；运行 `打开GPT娘.cmd`。如果其他应用盖住了主窗口，挂件会一起被盖住。

**额度数字不更新？** 点击气泡里的刷新按钮，检查 Codex 的 ChatGPT 登录状态。成功查询但账户未提供的窗口会整条折叠；读取异常时显示 `—` 或明确标记为上次同账号的额度。

**Codex 更新之后额度一直显示 `—`？** 挂件会重新寻找当前 Codex 可执行文件。若仍无法恢复，重跑一次 `安装GPT娘.cmd`，然后检查当前客户端的登录状态；原有位置、大小、音量和自定义语录会保留。

**旧安装占用了自动启动任务？** 先从旧目录运行停用脚本，再安装新版。安装器会拒绝覆盖不属于当前目录的启动项。

**使用挂件会有封号风险吗？** 查询使用 [Codex 官方 App Server 文档](https://learn.chatgpt.com/docs/app-server) 中的 `account/read` 与 `account/rateLimits/read`，由本机 Codex 复用现有登录；这条查询链不创建聊天、不发起模型生成、不共享登录凭据，也不绕过额度限制。默认可见时每 60 秒查询一次，隐藏时暂停。但官方未对第三方额度挂件给出免封承诺；[使用条款](https://openai.com/policies/terms-of-use/) 对自动化提取数据、账号共享及绕过限制均有约束，成功读取不能证明永久合规或零风险。请保留默认查询频率，接口拒绝访问时不要改为绕过认证或限制。

**杀毒软件或 SmartScreen 报警？** 安装包里没有 exe / dll，全部是 PowerShell、VBS 与 Node 脚本。由于安装链需要在受限策略下运行（`-ExecutionPolicy Bypass`）、以隐藏窗口常驻并注册登录任务，未签名的脚本包可能被启发式规则误报。请先按 Release 中的 SHA256 校验文件核对来源，再决定是否放行；如果设备策略不允许运行脚本，请不要绕过策略。

**系统或企业策略阻止脚本？** 此版本依赖 Windows PowerShell / WPF、Windows Script Host 和当前用户计划任务。请遵循设备管理策略；项目不会修改系统安全策略。

## 开发与验证

无需安装 npm 依赖。运行额度与刷新测试：

```powershell
cd gpt-niang-usage
node --test tests/*.test.mjs
npm run test:windows
```

只检查安装条件，不创建任务、不安装插件：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\gpt-niang-usage\Install.ps1 -CheckOnly
```

界面实现为 Windows PowerShell / WPF，额度查询和 MCP 服务使用 Node.js。窗口识别与接口依赖当前 Codex 桌面端实现，后续客户端更新可能需要适配。Windows 界面与 macOS 原生 companion 分别实现；未提供 Linux 版本。

## 反馈与参与

遇到问题可以 [提交中文问题反馈](https://github.com/T7moris/GPT-Niang-Usage-Widget/issues/new)。请说明 Windows / Codex / 挂件版本、复现步骤以及期望效果；截图请裁去对话、账号和其他私人信息。不要上传登录文件或整个状态目录。

欢迎改进窗口兼容性、安装流程和可读性；改动后请运行上面的检查。这个版本的角色是静态半身配合按压动画；不包含完整桌宠动作；macOS companion 见上面的说明，尚无 Linux 支持。

## 致谢与许可

交互参考 [DeepSeek-Balance-Whale-Widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget)，本项目采用单独实现的 WPF 界面、原创语录及合成提示音，没有打包 DSH 原角色、动图或音效。具体对照见 [功能对照](gpt-niang-usage/DSH功能对照.md)。

代码采用 [MIT License](LICENSE)。龙娘图由 ImageGen 根据用户提供的角色参考生成；参考角色及相关形象权利仍归相应权利人，代码许可不构成对第三方角色或商标的授权。详见 [素材说明](gpt-niang-usage/assets/生成说明.md)。
