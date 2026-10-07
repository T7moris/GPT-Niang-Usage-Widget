import AppKit
import SwiftUI
import GPTNiangCore
import Darwin
import os

@main
struct GPTNiangEntry {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
        withExtendedLifetime(delegate) {}
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var model: WidgetModel!
    private var panel: NSPanel!
    private var settingsWindow: NSWindow?
    private var speedWindow: NSWindow?
    private let speedStore = ThreadSpeedStore()
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var lockDescriptor: Int32 = -1
    private var hostRect: CGRect?
    private var lastHostNumber: Int?
    private var wasCodexFrontmost = false
    private var missingHostSince: Date?
    private var dragOrigin: CGPoint?
    private var dragEvents = 0
    private var diagnosticsURL: URL?
    private let logger = Logger(subsystem: "io.github.t7moris.GPTNiangMac", category: "window")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = ProcessInfo.processInfo.arguments
        func argument(_ flag: String) -> String? {
            guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else { return nil }
            return args[index + 1]
        }
        let dataDirectory = argument("--data-dir").map { URL(fileURLWithPath: $0, isDirectory: true) } ??
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/GPTNiangUsage", isDirectory: true)
        try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        lockDescriptor = Darwin.open(dataDirectory.appendingPathComponent("gui.lock").path, O_CREAT | O_RDWR, 0o600)
        guard lockDescriptor >= 0, flock(lockDescriptor, LOCK_EX | LOCK_NB) == 0 else {
            // Reopening the app must not create a second character or quota worker.
            NSApp.terminate(nil); return
        }
        guard let resources = Bundle.main.resourceURL else { NSApp.terminate(nil); return }
        diagnosticsURL = argument("--diagnostics").map { URL(fileURLWithPath: $0) }
        model = WidgetModel(dataDirectory: dataDirectory, resources: resources)
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 378, height: 378),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "GPT 娘額度掛件"
        panel.backgroundColor = .clear; panel.isOpaque = false; panel.hasShadow = false
        panel.isFloatingPanel = false; panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: WidgetView(model: model, onDrag: { [weak self] in self?.drag($0) }, onSettings: { [weak self] in self?.showSettings() }))
        buildMenu()
        model.start()
        updateWindow()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateWindow() }
        }
        if args.contains("--speed") { showSpeed() }
        logger.info("macOS widget launched")
    }
    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate(); model?.stop(); speedStore.stop()
        if lockDescriptor >= 0 { Darwin.close(lockDescriptor) }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window === speedWindow { speedStore.stop() }
            if window === settingsWindow || window === speedWindow { NSApp.setActivationPolicy(.accessory) }
        }
    }
    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "GPT 娘")
        let menu = NSMenu()
        for (title, selector) in [("GPT 娘 · Codex 額度", #selector(showQuota)), ("刷新額度", #selector(refresh)), ("來一句語錄", #selector(quote)), ("聊天速度…", #selector(showSpeed))] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: ""); item.target = self; menu.addItem(item)
        }
        menu.addItem(.separator())
        let settings = NSMenuItem(title: "設定…", action: #selector(showSettings), keyEquivalent: ","); settings.target = self; menu.addItem(settings)
        let quit = NSMenuItem(title: "退出 GPT 娘", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"); menu.addItem(quit)
        statusItem?.menu = menu
        let main = NSMenu()
        let appMenu = NSMenuItem()
        let applicationMenu = NSMenu(title: "GPT 娘")
        for item in menu.items {
            if item.isSeparatorItem { applicationMenu.addItem(.separator()); continue }
            let copy = NSMenuItem(title: item.title, action: item.action, keyEquivalent: item.keyEquivalent)
            copy.target = item.target; applicationMenu.addItem(copy)
        }
        appMenu.submenu = applicationMenu; main.addItem(appMenu)
        let editItem = NSMenuItem(title: "編輯", action: nil, keyEquivalent: "")
        let edit = NSMenu(title: "編輯")
        for (title, selector, key) in [("復原", Selector(("undo:")), "z"), ("剪下", #selector(NSText.cut(_:)), "x"), ("複製", #selector(NSText.copy(_:)), "c"), ("貼上", #selector(NSText.paste(_:)), "v"), ("全選", #selector(NSText.selectAll(_:)), "a")] {
            edit.addItem(withTitle: title, action: selector, keyEquivalent: key)
        }
        editItem.submenu = edit; main.addItem(editItem); NSApp.mainMenu = main
    }
    @objc private func showQuota() { model.showQuota(); updateWindow() }
    @objc private func refresh() { model.refresh() }
    @objc private func quote() { model.showQuote() }
    @objc private func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 620), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "GPT 娘設定"; window.isReleasedWhenClosed = false; window.delegate = self
            window.contentView = NSHostingView(rootView: SettingsView(model: model))
            window.center(); settingsWindow = window
        }
        NSApp.setActivationPolicy(.regular); NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    @objc private func showSpeed() {
        if speedWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 580), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "GPT 娘 · 聊天速度"; window.isReleasedWhenClosed = false; window.delegate = self
            window.contentView = NSHostingView(rootView: ThreadSpeedView(store: speedStore)); window.center(); speedWindow = window
        }
        speedStore.start(model: model)
        NSApp.setActivationPolicy(.regular); NSApp.activate(ignoringOtherApps: true)
        speedWindow?.makeKeyAndOrderFront(nil)
    }
    private func codexWindow() -> (CGRect, Int)? {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.openai.codex").first,
              !app.isHidden,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return nil }
        var candidates: [(CGRect, Int)] = []
        for window in windows {
            guard (window[kCGWindowOwnerPID as String] as? Int32) == app.processIdentifier,
                  (window[kCGWindowLayer as String] as? Int) == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = bounds["Width"], let height = bounds["Height"], width >= 480, height >= 300,
                  let number = window[kCGWindowNumber as String] as? Int else { continue }
            let quartz = CGRect(x: bounds["X"] ?? 0, y: bounds["Y"] ?? 0, width: width, height: height)
            let frame = WidgetPlacement.appKitRect(quartz: quartz, mainDisplayHeight: CGDisplayBounds(CGMainDisplayID()).height)
            candidates.append((frame, number))
        }
        return candidates.first(where: { $0.1 == lastHostNumber }) ?? candidates.first
    }
    private func updateWindow() {
        guard model != nil, panel != nil else { return }
        var size = CGSize(width: 378 * model.scale, height: 378 * model.scale)
        let host = codexWindow()
        let codexFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.openai.codex"
        var visible = false
        if model.followCodex {
            panel.level = .normal
            if let (rect, number) = host {
                missingHostSince = nil
                let screen = NSScreen.screens.max { $0.frame.intersection(rect).area < $1.frame.intersection(rect).area } ?? NSScreen.main!
                let area = WidgetPlacement.usableArea(host: rect, visibleScreen: screen.visibleFrame)
                hostRect = area
                let fitted = min(model.scale, area.width / 378, area.height / 378)
                if abs(model.displayScale - fitted) > 0.001 { model.displayScale = fitted }
                size = CGSize(width: 378 * fitted, height: 378 * fitted)
                if dragOrigin == nil { let frame = WidgetPlacement.frame(host: rect, visibleScreen: screen.visibleFrame, size: size, x: model.x, y: model.y); if panel.frame != frame { panel.setFrame(frame, display: true) } }
                if !panel.isVisible || lastHostNumber != number || (codexFrontmost && !wasCodexFrontmost) {
                    panel.order(.above, relativeTo: number)
                }
                visible = true; lastHostNumber = number; if model.trackingNote != nil { model.trackingNote = nil }
            } else {
                if missingHostSince == nil { missingHostSince = Date() }
                let appHidden = NSRunningApplication.runningApplications(withBundleIdentifier: "com.openai.codex").first?.isHidden ?? true
                if !appHidden && Date().timeIntervalSince(missingHostSince!) < 0.75 {
                    visible = panel.isVisible
                } else {
                    if panel.isVisible { panel.orderOut(nil) }; lastHostNumber = nil; hostRect = nil
                    let note = "未找到可見的 Codex 主視窗。你仍可關閉跟隨，在桌面顯示掛件。"
                    if model.trackingNote != note { model.trackingNote = note }
                }
            }
        } else {
            panel.level = .floating
            let screen = NSScreen.main ?? NSScreen.screens[0]
            let fitted = min(model.scale, screen.visibleFrame.width / 378, screen.visibleFrame.height / 378)
            if abs(model.displayScale - fitted) > 0.001 { model.displayScale = fitted }
            size = CGSize(width: 378 * fitted, height: 378 * fitted)
            if dragOrigin == nil {
                let frame = WidgetPlacement.frame(host: screen.visibleFrame, visibleScreen: screen.visibleFrame, size: size, x: model.x, y: model.y)
                panel.setFrame(frame, display: true)
            }
            if !panel.isVisible || panel.level != .floating { panel.orderFrontRegardless() }; visible = true; hostRect = screen.visibleFrame
        }
        wasCodexFrontmost = codexFrontmost
        model.writePresence(visible: visible)
        if let diagnosticsURL {
            let values: [String: Any] = ["visible": panel.isVisible, "followCodex": model.followCodex, "hostFound": host != nil,
                "hostWindow": host?.1 ?? 0, "frame": NSStringFromRect(panel.frame), "quotaOK": model.snapshot.ok,
                "queryOK": model.snapshot.queryOk ?? false, "quotaWindowCount": model.snapshot.windows.count,
                "hasMessage": model.message != nil, "bubbleVisible": model.bubble, "scale": model.scale,
                "settingsVisible": settingsWindow?.isVisible ?? false, "speedVisible": speedWindow?.isVisible ?? false, "speedRows": speedStore.rows.count, "dragEvents": dragEvents, "displayScale": model.displayScale, "at": Date().timeIntervalSince1970]
            if let data = try? JSONSerialization.data(withJSONObject: values, options: [.prettyPrinted, .sortedKeys]) { try? data.write(to: diagnosticsURL, options: .atomic) }
        }
    }
    private func drag(_ translation: CGSize) {
        if translation == .zero {
            if let area = hostRect {
                let travel = max(0, area.width - panel.frame.width - 24)
                if model.x * travel <= 18 { model.x = 0 }
                if (1 - model.x) * travel <= 18 { model.x = 1 }
            }
            dragOrigin = nil; return
        }
        dragEvents += 1
        if dragOrigin == nil { dragOrigin = panel.frame.origin }
        guard let origin = dragOrigin, let area = hostRect else { return }
        let proposed = CGPoint(x: origin.x + translation.width, y: origin.y - translation.height)
        let insetX = min(12, max(0, area.width - panel.frame.width))
        let insetY = min(12, max(0, area.height - panel.frame.height))
        let usableX = max(0, area.width - panel.frame.width - 24)
        let usableY = max(0, area.height - panel.frame.height - 24)
        if usableX > 0 { model.x = min(1, max(0, (proposed.x - area.minX - insetX) / usableX)) }
        if usableY > 0 { model.y = min(1, max(0, (proposed.y - area.minY - insetY) / usableY)) }
        // Do not resize or reorder the window while its drag gesture is active.
        panel.setFrameOrigin(CGPoint(x: area.minX + insetX + usableX * model.x, y: area.minY + insetY + usableY * model.y))
    }
}

private extension CGRect { var area: CGFloat { isNull ? 0 : width * height } }
