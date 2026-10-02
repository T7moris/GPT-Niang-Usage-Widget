# GPT娘额度挂件

让一只白发紫瞳的小龙娘，陪你看 Codex 的剩余额度。

**Windows 桌面挂件 · 5 小时 / 每周额度 · 中文语录 · 当前版本 1.2.4**

[**下载最新版**](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest) · [安装方法](#安装) · [更新记录](更新记录.md) · [反馈问题](https://github.com/T7moris/GPT-Niang-Usage-Widget/issues/new)

<img src="gpt-niang-usage/assets/gpt-dragon-niang-bust.png" alt="无嘴巴的白发龙娘半身形象" width="240">

## 能做什么

- **点角色看额度**：按接口实际返回的窗口显示 5 小时或每周剩余百分比；横条越满，剩余额度越多。成功查询时折叠未返回的整条窗口；查询失败会显示异常，重置时间为空时仍保留百分比。
- **切换账号后重新读取**：下一次查询识别到账号变化时，先清空旧账号的额度。只读取 Codex 当前登录的账号，不提供多账号列表、账号切换或同时查询多个账号的功能。
- **点气泡看语录**：再点收起，显示完成约 5 秒后也会自动收起；支持编辑自己的语录。
- **按压与回弹**：半身角色、分段气泡动画和轻提示音，可调整音量或静音。
- **拖动与缩放**：靠近左右边缘吸附，角色面向窗口内侧，文字保持正向。
- **跟随主窗口**：失去焦点时保留；其他窗口覆盖主窗口时，也会覆盖挂件。最小化或隐藏主窗口后挂件隐藏。
- **自动恢复**：当前用户登录后监测主窗口；重开客户端时自动显示。仅打开宠物 mini 不显示。

这是独立的 Windows 本地挂件及额度查询插件。它读取当前 Codex 登录账户的额度，**不会为读取额度创建聊天或调用模型**。它不是 OpenAI 或 DeepSeek 的官方项目。

## 安装

需要 **Windows 10 / 11、Node.js 20 或更新版本，以及已安装并用 ChatGPT 订阅登录的 Codex 桌面端**。

1. 打开 [Release 下载页](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest)，在 **Assets** 中下载 **`gpt-niang-usage-widget-v1.2.4-windows.zip`**。也可以使用 **Code → Download ZIP** 获取当前源码。
2. 将压缩包**完整解压**到准备长期保留的位置；保留 `.agents` 与 `gpt-niang-usage` 文件夹。
3. 双击根目录的 **`安装GPT娘.cmd`**，等待安装完成。
4. 打开 Codex 主窗口，龙娘会自动出现。额度查询工具可在新建的聊天中使用。

安装器会查找 Node.js 与 Codex，并注册本地插件及当前用户的自动启动任务。**不需要以管理员身份运行**。若缺少 Node.js，请先从 [Node.js 官方网站](https://nodejs.org/) 安装并重新打开安装器。

安装会在本机做这些事：向 Codex 注册一个**本地路径插件市场**及其中的额度插件（内含一个只读的额度查询工具）、在当前用户的启动文件夹创建快捷方式、注册一个**登录时自动启动**的用户级计划任务，并把偏好与额度快照写进 `%LOCALAPPDATA%\GPTNiangUsage\state`。它不写注册表、不安装系统服务、不修改系统安全策略。

### 安装包校验（建议）

本版 `gpt-niang-usage-widget-v1.2.4-windows.zip` 的 SHA256 见同一 [Release 下载页](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/tag/v1.2.4) 的 **`SHA256SUMS.txt`**。下载压缩包和校验文件后，确认计算出的哈希与文件中对应的一行一致。

在 PowerShell 中核对：

```powershell
Get-FileHash .\gpt-niang-usage-widget-v1.2.4-windows.zip -Algorithm SHA256
```

哈希不一致时先不要安装：可能是下载损坏、选错版本或文件被修改。请从本仓库的 Release 页面重新下载对应版本的压缩包和校验文件，再核对一次。哈希一致表示下载内容与校验文件对应，不能代替对脚本内容和来源的判断。

## 让 AI 帮你装

把下面这段发给任意能在你电脑上执行命令的 AI：

> 从 https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest 下载该版本的
> `gpt-niang-usage-widget-*-windows.zip` 和 `SHA256SUMS.txt`，核对压缩包的 SHA256。
> 校验一致后，完整解压到一个长期保留的位置（例如 `%LOCALAPPDATA%\Programs\GPTNiangUsage`），
> 运行解压目录里的 `安装GPT娘.cmd`，告诉我安装结果。如果已经安装过，先按 README 的更新步骤处理，保留原来的安装配置和个人数据。

前置条件：Windows 10 / 11、Node.js 20 或更新版本、已安装并用 ChatGPT 订阅登录的 Codex 桌面端。安装器注册的是**本地路径**插件市场，因此**不需要管理员权限，也不需要 git**。

这段提示会让 AI 下载并执行安装脚本。请确认它能访问你的 Windows 电脑，并在校验一致、依赖满足后再安装。

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

- 通过本机 Codex App Server 读取登录类型与额度窗口；查询过程中 Codex 可能需要与 OpenAI 通信。挂件没有自己的云服务器或遥测，不向自建或第三方服务上传数据。
- 不保存登录凭据、邮箱、对话内容；状态文件保存额度数字、时间、显示偏好、运行状态，以及用于隔离账号快照的身份哈希。无法确认当前账号时清空旧额度；已确认同账号的刷新失败会明确标记旧快照。
- 账号识别使用接口返回的账号标识、邮箱等信息的哈希，不保存这些信息的原文。若接口未返回能区分组织的标识，同邮箱、同套餐下的组织切换可能无法被识别；切换后请手动刷新，以获取当前额度。刷新本身不能补足缺失的组织标识。
- 新安装的偏好和状态保存在 `%LOCALAPPDATA%\GPTNiangUsage\state`，安装路径记录保存在本机生成的 `installation.json`。
- 超过 3 分钟的数据标为旧快照；重置时间已到时，会等待新数据，不擅自把额度补为 100%。
- 使用 API Key 登录或接口不可用时显示读取异常；成功查询但没有相应额度窗口时折叠该窗口，不根据套餐名称猜测支持情况。
- 界面、MCP 工具与控制命令共用一个后台额度进程，统一写入状态文件。挂件可见时约每 60 秒定时查询，隐藏时暂停定时查询；手动刷新或调用工具仍会触发查询。窗口位置由事件更新，并以每秒一次检测兜底；这个检测不会每秒查询额度。
- 挂件按设计常驻：登录后由用户级计划任务启动一个隐藏的守护进程，用于在 Codex 主窗口出现时显示挂件；额度进程异常退出后也会尝试恢复。在任务管理器里结束挂件进程可能被自动恢复。临时退出请在菜单中选择「退出 GPT 娘」；不再自动启动请运行 `停用GPT娘.cmd`。

本仓库不包含作者的本机安装配置、账户快照、个人语录或聊天截图。

## 更新、移动与卸载

更新时先备份自定义内容，并在**原目录**运行 `停用GPT娘.cmd`，等待停用完成。将新版压缩包解压出的内容覆盖到原目录，保留本机生成的 `gpt-niang-usage/installation.json`，不要用整个新目录替换旧目录；再运行 `安装GPT娘.cmd`。安装器会沿用原有数据目录和偏好。

需要移动文件夹时，先在原目录运行 `停用GPT娘.cmd`，等待停用完成，再移动并重新安装。安装器允许已停用、旧路径已不存在的目录迁移，并保留原数据目录与偏好。复制仍存在的旧安装目录或直接移动运行中的目录会被拒绝。

**彻底移除**：`停用GPT娘.cmd` 会移除计划任务、启动文件夹快捷方式、插件与市场登记并停止进程，但会**保留**程序文件与偏好数据。要完全清理：

1. 双击 `停用GPT娘.cmd`；
2. 删除程序目录前，查看 `gpt-niang-usage/installation.json` 中的 `dataDir`，记下实际数据目录；
3. 删除解压出来的整个程序目录，以及上一步记录的本项目数据目录（内含偏好、自定义语录和额度快照，不含登录凭据）。新安装默认位于 `%LOCALAPPDATA%\GPTNiangUsage\state`；旧安装或迁移安装可能保留其他路径。

停用脚本在偏好数据目录已被删除时也能完成停用。

## 常见问题

**看不到角色？** 确认打开的是主窗口而非宠物 mini，主窗口没有最小化；运行 `打开GPT娘.cmd`。如果其他应用盖住了主窗口，挂件会一起被盖住。

**额度数字不更新？** 点击气泡里的刷新按钮，检查 Codex 的 ChatGPT 登录状态。成功查询但账户未提供的窗口会整条折叠；读取异常时显示 `—` 或明确标记为上次同账号的额度。

**Codex 更新之后额度一直显示 `—`？** 更新可能改变 Codex 可执行文件路径。先重新打开 Codex，再运行一次 `安装GPT娘.cmd`，让安装器重新查找路径；原有位置、大小、音量和自定义语录会保留。如果仍然失败，请检查登录状态和错误提示；接口或插件机制变化时可能需要新版挂件适配，重新安装不能保证解决所有问题。

**旧安装占用了自动启动任务？** 先从旧目录运行停用脚本，再安装新版。安装器会拒绝覆盖不属于当前目录的启动项。

**使用挂件会有封号风险吗？** 查询使用 [Codex 官方 App Server 文档](https://learn.chatgpt.com/docs/app-server) 中的 `account/read` 与 `account/rateLimits/read`，由本机 Codex 复用现有登录；这条查询链不创建聊天、不发起模型生成、不共享登录凭据，也不绕过额度限制。默认可见时每 60 秒查询一次，隐藏时暂停。但官方未对第三方额度挂件给出免封承诺；[使用条款](https://openai.com/policies/terms-of-use/) 对自动化提取数据、账号共享及绕过限制均有约束，成功读取不能证明永久合规或零风险。请保留默认查询频率，接口拒绝访问时不要改为绕过认证或限制。

**杀毒软件或 SmartScreen 报警？** 安装包不附带 exe / dll；启动入口使用 CMD、PowerShell、VBS 与 Node 脚本，并调用电脑上已有的运行时。启动命令使用 `-ExecutionPolicy Bypass`，程序会以隐藏窗口常驻并注册登录任务，这些行为可能触发安全软件警告。不能仅凭文件类型或哈希一致判定警告是误报；请核对下载来源、校验文件及脚本内容。如果设备策略不允许运行脚本，请不要绕过策略。

**系统或企业策略阻止脚本？** 此版本依赖 Windows PowerShell / WPF、Windows Script Host 和当前用户计划任务。请遵循设备管理策略；项目不会修改系统安全策略。

## 开发与验证

无需安装 npm 依赖。以下检查覆盖额度解析、账号快照隔离、刷新并发，以及 Windows 安装、进程恢复和 WPF 界面；Windows 检查需要在 Windows 上运行：

```powershell
cd gpt-niang-usage
node --test tests/*.test.mjs
npm run test:windows
```

只检查安装条件，不创建任务、不安装插件：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\gpt-niang-usage\Install.ps1 -CheckOnly
```

正式发布前，请同步修改 `gpt-niang-usage/package.json` 与 `gpt-niang-usage/.codex-plugin/plugin.json` 中的版本号，并更新本页及更新记录。将版本变更推送到 `main` 后，GitHub Actions 会在 Windows 上测试、打包，并发布同版本的 ZIP 和 `SHA256SUMS.txt`；已存在的版本不会重复发布。仅修改文档不触发发布。

界面实现为 Windows PowerShell / WPF，额度查询和 MCP 服务使用 Node.js。窗口识别与接口依赖当前 Codex 桌面端实现，后续客户端更新可能需要适配。当前支持 Windows，未提供 macOS / Linux 版本。

## 反馈与参与

遇到问题可以 [提交中文问题反馈](https://github.com/T7moris/GPT-Niang-Usage-Widget/issues/new)。请说明 Windows / Codex / 挂件版本、复现步骤以及期望效果；截图请裁去对话、账号和其他私人信息。不要上传登录文件或整个状态目录。

欢迎改进窗口兼容性、安装流程和可读性；改动后请运行上面的检查。这个版本的角色是静态半身配合按压动画；不包含完整桌宠动作或 macOS / Linux 支持。

## 致谢与许可

交互参考 [DeepSeek-Balance-Whale-Widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget)，本项目采用单独实现的 WPF 界面、原创语录及合成提示音，没有打包 DSH 原角色、动图或音效。具体对照见 [功能对照](gpt-niang-usage/DSH功能对照.md)。

代码采用 [MIT License](LICENSE)。龙娘图由 ImageGen 根据用户提供的角色参考生成；参考角色及相关形象权利仍归相应权利人，代码许可不构成对第三方角色或商标的授权。详见 [素材说明](gpt-niang-usage/assets/生成说明.md)。
