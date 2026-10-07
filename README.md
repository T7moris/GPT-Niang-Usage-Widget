# GPT娘额度挂件

让一只白发紫瞳的小龙娘，陪你看 Codex 的剩余额度。

**Windows / macOS 桌面挂件 · 5 小时 / 每周额度 · 中文语录 · 当前版本 1.3.0**

[**下载最新版**](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest) · [Windows 安装](#windows-安装) · [macOS 安装](#macos-安装) · [更新记录](更新记录.md) · [反馈问题](https://github.com/T7moris/GPT-Niang-Usage-Widget/issues/new)

<img src="gpt-niang-usage/assets/gpt-dragon-niang-bust.png" alt="无嘴巴的白发龙娘半身形象" width="240">

## 能做什么

- **点角色看额度**：按接口实际返回的窗口显示 5 小时或每周剩余百分比；横条越满，剩余额度越多。成功查询时折叠未返回的整条窗口；查询失败会显示异常，重置时间为空时仍保留百分比。
- **点气泡看语录**：再点收起，显示完成约 5 秒后也会自动收起；支持编辑自己的语录。
- **按压与回弹**：半身角色、分段气泡动画和轻提示音，可调整音量或静音。
- **拖动与缩放**：靠近左右边缘吸附，角色面向窗口内侧，文字保持正向。
- **跟随主窗口**：失去焦点时保留；其他窗口覆盖主窗口时，也会覆盖挂件。最小化或隐藏主窗口后挂件隐藏。Mac 可在设置中关闭跟随，让挂件留在桌面。
- **登录启动**：Windows 安装器默认配置自动启动和主窗口重开后的恢复；Mac 需要自行开启设置中的「登入 Mac 時自動開啟」。
- **Mac 聊天速度面板**：从菜单栏打开，显示本地统计区间内的输出平均速度，包含推理、网络和工具等待，**不代表模型实时生成速度**。

这是独立的桌面挂件；Windows 同时提供额度查询插件，Mac 为原生应用，不注册 MCP 插件。它读取当前 Codex 登录账户的额度，**不会为读取额度创建聊天或调用模型**。它不是 OpenAI 或 DeepSeek 的官方项目。

## 安装

两边都需要 **Node.js 20 或更新版本**，以及已安装并用 ChatGPT 账号登录的 **Codex 桌面端**。下载包不附带 Node.js；缺少时请先从 [Node.js 官方网站](https://nodejs.org/) 安装。

在 [Release 下载页](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest) 的 **Assets** 中选择自己的系统：

| 系统 | v1.3.0 安装包 | 安装入口 |
| --- | --- | --- |
| Windows 10 / 11 | [gpt-niang-usage-widget-v1.3.0-windows.zip](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/download/v1.3.0/gpt-niang-usage-widget-v1.3.0-windows.zip) | 解压后运行 `安装GPT娘.cmd` |
| macOS 13+，Apple Silicon / Intel | [gpt-niang-usage-widget-v1.3.0-macos-universal.zip](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/download/v1.3.0/gpt-niang-usage-widget-v1.3.0-macos-universal.zip) | 解压后打开 `GPTNiangMac.app` |

GitHub 自动附带的 **Source code** 和 **Code → Download ZIP** 是源码，不是上述安装包。Mac 下载包内已包含通用应用，不需要 Swift 或 Xcode；Intel 和较旧 macOS 的实际界面表现仍需真机验证。尚无 Linux 版本。

### Windows 安装

1. 下载 Windows ZIP，将压缩包**完整解压**到准备长期保留的位置；保留 `.agents` 与 `gpt-niang-usage` 文件夹。
2. 双击根目录的 **`安装GPT娘.cmd`**，等待安装完成。**不需要管理员权限，也不需要 git**。
3. 打开 Codex 主窗口，龙娘会自动出现。额度查询工具可在新建的聊天中使用。

安装器会查找 Node.js 与 Codex，注册一个本地路径插件市场及其中的只读额度查询工具，在当前用户的启动文件夹创建快捷方式，并注册登录时自动启动的用户级计划任务。偏好与额度快照写入 `%LOCALAPPDATA%\GPTNiangUsage\state`。它不写注册表、不安装系统服务、不修改系统安全策略。

### macOS 安装

1. 下载 Mac ZIP，解压后把 **`GPTNiangMac.app`** 移入「应用程序」或其他准备长期保留的位置。
2. 打开应用，再打开 Codex 主窗口。Mac 不使用 `.cmd` 或 PowerShell 安装器。
3. 双击或右键角色打开设置，也可从菜单栏进入。需要登录启动时，再开启 **「登入 Mac 時自動開啟」**；系统可能要求在「登录项」中批准。
4. 在菜单栏选择 **「聊天速度…」**，可打开独立的本地速度面板。

Mac 包仅有本地签名（ad-hoc），未使用 Apple Developer ID 签名、未经过 Apple 公证。首次打开可能被系统阻止；确认来源并核对下面的 SHA256 后，按 [Apple 官方说明](https://support.apple.com/102445) 在「系统设置 → 隐私与安全性」确认打开。

Mac 的位置跟随目标为 60 Hz，仍使用轮询，不能保证拖动时零延迟；多窗口选择、快速拖动和旧系统的表现仍需真机验证。完整功能、源码构建和诊断说明见 [macOS 使用说明](macos/README.md)。

### 安装包校验（建议）

同一 [v1.3.0 Release](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/tag/v1.3.0) 的 **[SHA256SUMS.txt](https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/download/v1.3.0/SHA256SUMS.txt)** 包含两个包的校验值。下载后计算自己的安装包哈希，与文件中**同名文件**的一行比较。

Windows，在 PowerShell 中运行：

```powershell
Get-FileHash .\gpt-niang-usage-widget-v1.3.0-windows.zip -Algorithm SHA256
```

macOS，在终端中进入下载目录后运行：

```sh
shasum -a 256 gpt-niang-usage-widget-v1.3.0-macos-universal.zip
```

十六进制字母大小写不影响比较。哈希不一致说明下载文件与 Release 校验值不一致，可能是下载损坏或内容被改动，请不要安装。请只从本仓库的 Release 页面下载；第三方加速镜像不能当作可信来源。

## 让 AI 帮你装

把对应系统的这段发给能在你电脑上执行命令的 AI。

**Windows：**

> 从 https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest 下载 Windows 安装包与 SHA256SUMS.txt，先核对来源和哈希，再完整解压到长期保留的位置（例如 `%LOCALAPPDATA%\Programs\GPTNiangUsage`），运行 `安装GPT娘.cmd` 并告诉我结果。先检查 Node.js 20+ 和 Codex 的 ChatGPT 登录状态。

**macOS：**

> 从 https://github.com/T7moris/GPT-Niang-Usage-Widget/releases/latest 下载 macOS 通用安装包与 SHA256SUMS.txt，先核对来源和哈希，再解压并将 `GPTNiangMac.app` 放入「应用程序」。检查 Node.js 20+ 和 Codex 的 ChatGPT 登录状态，打开应用并告诉我结果。若系统要求首次打开确认，请告诉我具体提示，由我在系统设置中确认。

## 使用

| 操作 | 效果 |
| --- | --- |
| 点角色 | 查看剩余额度；已在额度页时重新计时 |
| 点额度气泡 | 切换到随机语录 |
| 再点语录气泡 | 收起气泡 |
| 拖动角色 | 调整在主窗口内的位置 |
| 右键角色 | 打开设置，调整大小、声音、语录与位置 |
| Windows：双击 `打开GPT娘.cmd` | 手动恢复显示；重复打开不会叠加第二只 |
| Windows：菜单选择「退出 GPT 娘」 | 本次主窗口会话中退出，下次重开主窗口恢复 |
| Windows：双击 `停用GPT娘.cmd` | 停用自动显示，移除任务、启动项与插件登记，保留程序文件与偏好 |
| Mac：双击角色或从菜单栏进入设置 | 调整外观、窗口跟随和登录启动 |
| Mac：菜单选择「退出 GPT 娘」 | 退出应用和后台 helper；需重新打开 `.app` 才会再次显示 |

## 数据与隐私

- 额度通过本机 Codex App Server 查询。项目没有自己的云服务器、遥测或外部上传功能。
- 不保存登录凭据、邮箱或对话正文；状态文件保存额度数字、时间、显示偏好、运行状态，以及用于隔离账号快照的身份哈希。无法确认账号时清空旧额度；同账号刷新失败时明确标记旧快照。
- Mac 聊天速度面板会只读本机线程索引和会话日志，提取标题、输出计数和时间戳，不输出或保存对话正文。仅在面板打开时运行，每 3 秒更新；关闭面板或退出应用时停止。Codex 内部日志格式变化可能使指标不可用。
- 当前账号识别使用邮箱和套餐，无法可靠区分同邮箱、同套餐下的组织切换；切换组织后应手动刷新额度。
- 超过 3 分钟的数据标为旧快照；重置时间已到时等待新数据，不擅自把额度补为 100%。
- 使用 API Key 登录或接口不可用时显示读取异常；成功查询但没有相应额度窗口时折叠该窗口，不根据套餐名称猜测支持情况。
- 两边共用单实例额度 worker 实现，可见时默认每 60 秒查询一次，隐藏时暂停。Windows 的界面、MCP 与控制命令复用此 worker；Mac 原生应用启动自己的 worker，不注册 MCP 插件。
- Windows 的位置跟随使用事件更新和每秒兜底检测；Mac 对选定窗口按目标 60 Hz 采样、每秒 4 次重新发现窗口。提高位置更新频率不会同时提高额度查询频率。

默认数据位置：

| 系统 | 目录 |
| --- | --- |
| Windows | `%LOCALAPPDATA%\GPTNiangUsage\state` |
| macOS | `~/Library/Application Support/GPTNiangUsage` |

`installation.json` 由本机生成，不随安装包分发。本仓库不包含作者的本机安装配置、账户快照、个人语录或聊天截图。

## 更新、移动与卸载

### Windows

在**原目录**覆盖新版文件，再运行 `安装GPT娘.cmd`；安装器保留原有数据目录和偏好。安装前请先备份自定义内容。

需要移动文件夹时，先在原目录运行 `停用GPT娘.cmd`，等待停用完成，再移动并重新安装。安装器允许已停用、旧路径已不存在的目录迁移，并保留原数据目录与偏好。复制仍存在的旧安装目录或直接移动运行中的目录会被拒绝。

要彻底移除：

1. 运行 `停用GPT娘.cmd`，移除计划任务、启动快捷方式、插件与市场登记并停止进程。
2. 删除整个程序目录。
3. 如需清除偏好、自定义语录和额度快照，再删除 `%LOCALAPPDATA%\GPTNiangUsage`。

停用脚本在偏好目录已被删除时也能完成停用。直接在任务管理器中结束挂件会被守护进程恢复；要停用请使用上述脚本。

### macOS

更新时先退出 GPT 娘，再用新版本替换原位置的 `.app`；偏好和自定义语录保留在用户数据目录中。

移动应用前先关闭登录启动，退出应用，移到新位置后重新打开，需要时再开启登录启动。

卸载时先关闭登录启动，退出应用，再删除 `.app`。这会保留个人数据；如需一并清除，再删除 `~/Library/Application Support/GPTNiangUsage`。不要删除 Codex 自己的登录或会话目录。

## 常见问题

**看不到角色？** 确认 Codex 主窗口已打开且没有最小化。Windows 可运行 `打开GPT娘.cmd`；Mac 确认 GPT 娘应用正在运行，可在设置中关闭跟随以检查桌面显示。如果其他应用盖住主窗口，跟随模式下挂件也会被盖住。

**额度数字不更新？** 点击气泡里的刷新按钮，检查 Codex 的 ChatGPT 登录状态；Mac 也可从菜单栏刷新。成功查询但账户未提供的窗口会整条折叠；读取异常时显示 `—` 或明确标记为上次同账号的额度。

**Codex 更新之后额度一直显示 `—`？** 挂件会重新寻找当前 Codex 可执行文件。Windows 可重跑 `安装GPT娘.cmd`；Mac 可退出并重开 GPT 娘，检查 Node.js 和 Codex 登录状态。原有偏好会保留。

**Mac 提示找不到 Node.js？** 下载包不附带 Node.js。安装 Node.js 20+ 后退出并重新打开 GPT 娘；自定义 Node 路径及开发启动方式见 [macOS 使用说明](macos/README.md)。

**Mac 无法打开应用？** 本版未经过 Apple 公证。先检查下载来源和 SHA256，再按 [Apple 官方说明](https://support.apple.com/102445) 查看「隐私与安全性」中的提示。

**Mac 聊天速度显示 `—`？** 至少需要两笔有效计数记录，且 Codex 本机日志格式必须兼容。面板显示的是统计区间平均值；不是实时测速，也不是缺少数据时自动估算。

**Windows 旧安装占用了自动启动任务？** 先从旧目录运行停用脚本，再安装新版。安装器会拒绝覆盖不属于当前目录的启动项。

**使用挂件会有封号风险吗？** 查询使用 [Codex 官方 App Server 文档](https://learn.chatgpt.com/docs/app-server) 中的 `account/read` 与 `account/rateLimits/read`，由本机 Codex 复用现有登录；这条查询链不创建聊天、不发起模型生成、不共享登录凭据，也不绕过额度限制。默认可见时每 60 秒查询一次，隐藏时暂停。但官方未对第三方额度挂件给出免封承诺；[使用条款](https://openai.com/policies/terms-of-use/) 对自动化提取数据、账号共享及绕过限制均有约束，成功读取不能证明永久合规或零风险。请保留默认查询频率，接口拒绝访问时不要改为绕过认证或限制。

**Windows 杀毒软件或 SmartScreen 报警？** Windows 包里没有 exe / dll，使用 PowerShell、VBS 与 Node 脚本。由于安装链使用 `-ExecutionPolicy Bypass`、隐藏窗口常驻并注册登录任务，未签名脚本包可能被启发式规则误报。请先核对 Release 的 SHA256 和来源，再决定是否放行；设备策略不允许运行脚本时请不要绕过策略。

**Windows 系统或企业策略阻止脚本？** Windows 版依赖 PowerShell / WPF、Windows Script Host 和当前用户计划任务。请遵循设备管理策略；项目不会修改系统安全策略。

## 开发与验证

无需安装 npm 依赖。两边都可在仓库根目录运行共享运行时测试：

```sh
cd gpt-niang-usage
node --test tests/*.test.mjs
```

Windows 上继续运行安装、生命周期与 WPF 测试：

```powershell
npm run test:windows
```

只检查 Windows 安装条件，不创建任务、不安装插件（在仓库根目录运行）：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\gpt-niang-usage\Install.ps1 -CheckOnly
```

Mac 上在仓库根目录运行：

```sh
swift test --package-path macos
./script/build_and_run.sh --build-only
codesign --verify --deep --strict dist/GPTNiangMac.app
```

打包与发布流程见 `.github/workflows/release.yml`。两个平台测试、构建与校验都通过后，才发布同一个 Release 和两个独立安装包。

Windows 界面使用 PowerShell / WPF，Mac 界面使用 SwiftUI / AppKit，额度查询使用共享 Node.js 后端。窗口识别与接口依赖当前 Codex 桌面端实现，后续客户端更新可能需要适配。实际拖动、多窗口切换及 Intel / 较旧 macOS 的界面行为仍需真机验证，CI 通过不等于完成所有桌面交互测试。

## 反馈与参与

遇到问题可以 [提交中文问题反馈](https://github.com/T7moris/GPT-Niang-Usage-Widget/issues/new)。请说明操作系统、CPU 架构（Mac）、Codex 与挂件版本、复现步骤以及期望效果；截图请裁去对话、账号和其他私人信息。不要上传登录文件或整个状态目录。

欢迎改进窗口兼容性、安装流程和可读性；改动后请运行相应平台的检查。角色为静态半身配合按压动画，不包含完整桌宠动作。

## 致谢与许可

感谢 @meaqua9420 贡献 macOS 原生版本（PR #3）、@TheRuabit 修复 Windows 安装器 UTF-8 解码（PR #4）、@Admilkk 改进额度显示与后台可靠性（PR #1）。

交互参考 [DeepSeek-Balance-Whale-Widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget)。Windows WPF 与 Mac 原生界面分别实现，使用原创语录及合成提示音，没有打包 DSH 原角色、动图或音效。具体对照见 [功能对照](gpt-niang-usage/DSH功能对照.md)。

代码采用 [MIT License](LICENSE)。龙娘图由 ImageGen 根据用户提供的角色参考生成；参考角色及相关形象权利仍归相应权利人，代码许可不构成对第三方角色或商标的授权。详见 [素材说明](gpt-niang-usage/assets/生成说明.md)。
