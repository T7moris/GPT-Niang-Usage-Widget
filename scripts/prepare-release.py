"""Validate platform archives, then prepare combined checksums and release notes."""
import hashlib
import json
import plistlib
import re
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = json.loads((root / 'gpt-niang-usage/package.json').read_text())['version']
manifest = json.loads((root / 'gpt-niang-usage/.codex-plugin/plugin.json').read_text())
if not re.fullmatch(r'\d+\.\d+\.\d+', version) or manifest['version'] != version:
    raise SystemExit('Invalid or inconsistent release version')
changelog = (root / '更新记录.md').read_text()
if changelog.split('## ', 1)[1].splitlines()[0] != version:
    raise SystemExit('First changelog entry must match the release version')
changes = changelog.split(f'## {version}\n', 1)[1].split('\n## ', 1)[0].strip()
dist = root / 'dist'
windows = f'gpt-niang-usage-widget-v{version}-windows.zip'
macos = f'gpt-niang-usage-widget-v{version}-macos-universal.zip'
checksums = []
for name in [windows, macos]:
    path = dist / name
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise SystemExit(f'Corrupt archive: {name}')
        if name == windows:
            packed = json.loads(archive.read('GPT娘额度挂件/gpt-niang-usage/.codex-plugin/plugin.json'))
            if packed['version'] != version:
                raise SystemExit('Windows archive version differs')
        else:
            info = plistlib.loads(archive.read('GPTNiangMac.app/Contents/Info.plist'))
            if info['CFBundleShortVersionString'] != version or info['CFBundleVersion'] != version:
                raise SystemExit('Mac archive version differs')
            required = ['Contents/MacOS/GPTNiangMac', 'Contents/Resources/Backend/runtime/refresh-client.mjs',
                        'Contents/Resources/Backend/runtime/thread-speed.mjs', 'Contents/Resources/gpt-dragon-niang-bust.png']
            if any('GPTNiangMac.app/' + entry not in archive.namelist() for entry in required):
                raise SystemExit('Mac archive is missing runtime resources')
            packed = json.loads(archive.read('GPTNiangMac.app/Contents/Resources/Backend/.codex-plugin/plugin.json'))
            if packed['version'] != version:
                raise SystemExit('Mac backend version differs')
    checksums.append(f'{hashlib.sha256(path.read_bytes()).hexdigest().upper()}  {name}')
(dist / 'SHA256SUMS.txt').write_text('\n'.join(checksums) + '\n')
notes = f'''## {version}

{changes}

### 下载与安装

| 系统 | 下载文件 | 安装方法 |
| --- | --- | --- |
| Windows 10 / 11 | `{windows}` | 完整解压，运行根目录的 `安装GPT娘.cmd` |
| macOS 13+（Apple Silicon / Intel） | `{macos}` | 解压，把 `GPTNiangMac.app` 移入「应用程序」后打开 |

两边都需要 Node.js 20+ 以及已用 ChatGPT 账号登录的 Codex 桌面端。Mac 下载包不需要 Swift/Xcode，不注册 Windows MCP 插件。Windows 旧版用户可在备份自定义内容后覆盖原目录并重新运行安装器；Mac 用户退出旧应用后替换 `.app`，偏好保存在用户数据目录中。

Mac 应用仅 ad-hoc 签名，未使用 Developer ID、未经过 Apple 公证。首次打开可能被系统阻止；确认来源和校验后，按 [Apple 官方说明](https://support.apple.com/102445) 在「系统设置 → 隐私与安全性」确认打开。未提供 Apple 开发者签名凭据，不承诺免提示安装。

### 验证与范围

发布流程在 Windows/macOS 上运行共享运行时测试、Windows 安装与 WPF 测试、Swift 行为测试。Mac 通用应用含 arm64 / x86_64，构建后及解压后均验证签名与架构。两个包版本、完整性及共享后端资源均经核对。两边全部通过后才发布。

仍需真实 Mac 上验证快速拖动、多窗口切换及 Intel / 较旧 macOS 的界面行为。Mac 位置跟随目标 60 Hz，使用轮询，不保证零延迟。聊天速度是本地计数检查点之间的平均值，包含推理、网络与工具等待，不代表模型实时生成速度。

`SHA256SUMS.txt` 同时包含两个安装包的校验值；GitHub 自动附带的 Source code 是源码，不是安装包。

感谢 @meaqua9420（PR #3，macOS 原生版本）、@TheRuabit（PR #4，UTF-8 安装修复）、@Admilkk（PR #1，额度与后台可靠性），以及 [@FusaishiHaruaki-afk](https://github.com/FusaishiHaruaki-afk)（PR #8 / #9，Go 实测、按窗口时长适配及 Mac 构建兼容）。窗口跟随优化见 PR #5。
'''
(dist / 'release-notes.md').write_text(notes)
print(f'Validated both platform archives for v{version}')
