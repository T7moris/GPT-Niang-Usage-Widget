# GPT 娘 macOS

A native macOS companion for the Windows GPT 娘 widget. The SwiftUI canvas ports
v1.2.5's character image, 378-point animation stage, cloud outline, thought bubbles,
press/rebound Bézier curves, staggered open/close animations, flowing palettes,
quote transitions, and original sound assets. AppKit owns the transparent panel,
window following, native pointer capture, and menu bar entry.

## Requirements and launch

- macOS 13 or newer. This development build was exercised on Apple Silicon / macOS 26.
- Node.js 20 or newer (no npm dependencies).
- Codex desktop installed and signed in with a ChatGPT account.
- Xcode command-line tools / Swift 5.9 or newer to build from source.

From the repository root:

```sh
./script/build_and_run.sh
```

The script builds and ad-hoc signs `dist/GPTNiangMac.app`, then opens the app bundle.
`--build-only` builds without launching; `--verify` also checks the process.
`--logs`, `--telemetry`, and `--debug` are available for development.
Passing `--speed` after a run mode opens the separate speed panel at launch.
`GPT_NIANG_BUILD_CACHE` optionally selects a build cache directory.

You can keep the `.app` in a permanent location and open it directly. The local
build is ad-hoc signed, not Apple notarized; a public distribution needs Developer
ID signing and notarization. The app finds the desktop's bundled Codex CLI on each
refresh and supports `GPT_NIANG_CODEX_APP` for a nonstandard Codex app location.
`GPT_NIANG_NODE` can select a custom Node executable.

## Interaction

- Click the character to show quota. Both quota and quotes hide five seconds after
  their reveal animation completes, matching the original.
- Click the quota cloud to see a quote; click the quote cloud to close it.
- Drag the character to reposition it. It snaps near the left/right edges and
  faces inward; the text remains upright.
- Double-click or right-click the character to open settings. The hover menu
  button and menu bar also provide settings.
- Settings include scale, audio, quote editing, the original color modes, random
  color probabilities, flow pause, special quote triggers, and click-to-advance.
- Following mode hides the panel when Codex has no visible main window. Turn
  following off to keep it on the desktop. Window bounds come from public
  WindowServer metadata; no accessibility or screen-recording permission is
  requested. Position checks run four times per second, with a 0.75-second grace period for transient missing metadata; this differs from the
  Windows version's native movement hooks. The panel stays at normal window level
  in following mode so other apps can cover it.
- Login launch is opt-in through macOS `SMAppService`. Enable it only after moving
  the app to its permanent location; macOS may request approval in Login Items.
- **聊天速度** in the menu bar opens a separate thread performance panel.

## Thread speed: interpretation and privacy

The speed panel reads the newest twelve unarchived entries from the local Codex
SQLite index in read-only mode, then incrementally tails only their local session
files. It extracts `event_msg/token_count` output counters and timestamps. It
computes **output counter delta / elapsed time between accounting checkpoints**.
This interval average includes reasoning, network latency and tool waiting; it
is **not live model decoder/streaming tokens per second**. Missing or reset
counters display an unavailable value rather than an invented speed. The latest
sample and its interval are shown, so a historical sample is distinguishable from
an active one. The helper runs only while the speed window is open, updates every
three seconds, and is stopped on close or app exit.

Only titles and numeric counters are displayed; message bodies, credentials and
rate-limit credit information are not emitted or saved by this helper. Rollout
paths must resolve within the Codex sessions directories, including symlink
checks. The local database schema is an implementation detail and may change;
unsupported schemas show an error. `CODEX_HOME`, when already set, is respected.

Quota still uses the shared single-writer Node worker and the read-only App Server
methods `initialize`, `account/read` and `account/rateLimits/read`. It preserves
account isolation and stale/expired snapshot behavior and performs no chat or
model-generation call. The standalone Mac app does not register an MCP plugin or
change Codex configuration.

Local preferences/quota snapshots live at:

```text
~/Library/Application Support/GPTNiangUsage
```

To stop, choose **退出 GPT 娘**. To uninstall, first disable login launch if enabled,
quit, and remove the app. That preserves custom quotes and preferences; remove
the data directory separately only if you intend to discard them.

## Verification

```sh
cd gpt-niang-usage
node --test tests/*.test.mjs
cd ..
swift test --package-path macos
./script/build_and_run.sh --build-only
codesign --verify --deep --strict dist/GPTNiangMac.app
```

`--diagnostics /absolute/path.json` after the run mode enables a local development
snapshot of frame/visibility, gesture-event counts and quota readiness; it omits
account details and thread titles. Do not include local state in source archives.
Windows PowerShell/WPF tests must also run on Windows before merging.

The original MIT code license and the original character asset rights notice
continue to apply. This is an independent companion, not an official OpenAI app.
