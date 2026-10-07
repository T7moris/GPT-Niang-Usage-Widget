import AppKit
import Combine
import GPTNiangCore
import os

@MainActor
final class WidgetModel: ObservableObject {
    @Published var snapshot = UsageSnapshot(error: "正在讀取目前帳戶的額度…")
    @Published var message: String?
    @Published var bubble = false
    @Published var sceneStarted = Date()
    @Published var colorMode: ColorMode
    @Published var fullChance: Double
    @Published var textChance: Double
    @Published var colorPaused: Bool
    @Published var colorScope: ColorScope = .none
    @Published var specialQuotes: String
    @Published var bubbleTapAdvance: Bool
    @Published var displayScale = 1.0
    @Published var scale: Double
    @Published var volume: Double
    @Published var loginRequested: Bool
    @Published var followCodex: Bool
    @Published var x: Double
    @Published var y: Double
    @Published var quoteText = ""
    @Published var settingsError: String?
    @Published var refreshing = false
    @Published var trackingNote: String?
    let dataDirectory: URL
    let resources: URL
    let characterImage: NSImage?
    let defaults: UserDefaults
    private var worker: Process?
    private var stderr: FileHandle?
    private var timer: Timer?
    private var quotes: [Quote] = []
    private var sounds: [NSSound] = []
    private var lastQuote: String?
    private var quoteGeneration = 0
    private var refreshUntil = Date.distantPast
    private var lastStatusData: Data?
    private var lastChecked: Double?
    private let logger = Logger(subsystem: "io.github.t7moris.GPTNiangMac", category: "worker")

    init(dataDirectory: URL, resources: URL) {
        self.dataDirectory = dataDirectory; self.resources = resources
        characterImage = NSImage(contentsOf: resources.appendingPathComponent("gpt-dragon-niang-bust.png"))
        // Keep preferences together with quota state; no shared Codex config edits.
        let prefs = dataDirectory.appendingPathComponent("preferences.json")
        let values = (try? Data(contentsOf: prefs)).flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        defaults = .standard
        colorMode = ColorMode(rawValue: values["colorMode"] as? String ?? "mixed") ?? .mixed
        fullChance = min(100, max(0, values["fullChance"] as? Double ?? 0.5))
        textChance = min(100, max(0, values["textChance"] as? Double ?? 3))
        colorPaused = values["colorPaused"] as? Bool ?? false
        specialQuotes = values["specialQuotes"] as? String ?? "Token来，Token来"
        bubbleTapAdvance = values["bubbleTapAdvance"] as? Bool ?? false
        scale = min(1.5, max(0.6, values["scale"] as? Double ?? 1))
        volume = min(1, max(0, values["volume"] as? Double ?? 0.9))
        loginRequested = values["loginRequested"] as? Bool ?? false
        followCodex = values["followCodex"] as? Bool ?? true
        x = min(1, max(0, values["x"] as? Double ?? 1))
        y = min(1, max(0, values["y"] as? Double ?? 0))
        do {
            try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dataDirectory.path)
            try? FileManager.default.removeItem(at: dataDirectory.appendingPathComponent("stop.flag"))
        } catch { settingsError = "無法建立本機資料目錄：\(error.localizedDescription)" }
        loadQuotes()
    }

    func start() {
        startWorker()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }
    func stop() {
        timer?.invalidate(); timer = nil
        writePresence(visible: false)
        worker?.terminate(); worker = nil
        try? stderr?.close(); stderr = nil
    }
    func tick() {
        let file = dataDirectory.appendingPathComponent("status.json")
        if let data = try? Data(contentsOf: file), data != lastStatusData, let next = try? JSONDecoder().decode(UsageSnapshot.self, from: data) {
            lastStatusData = data; snapshot = next
            let checked = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["checkedAt"] as? Double
            if checked != lastChecked { lastChecked = checked; refreshing = false }
        }
        if Date() > refreshUntil { refreshing = false }
        if worker?.isRunning != true { startWorker() }
    }
    private func startWorker() {
        guard worker?.isRunning != true else { return }
        guard let node = findNode() else {
            snapshot = UsageSnapshot(error: "找不到 Node.js 20+。請先安裝 Node.js，再重新開啟 GPT 娘。")
            return
        }
        let backend = resources.appendingPathComponent("Backend")
        let configURL = dataDirectory.appendingPathComponent("installation.json")
        do {
            try writeJSON(["dataDir": dataDirectory.path, "nodePath": node.path, "codexPath": "codex"], to: configURL)
            let log = dataDirectory.appendingPathComponent("worker.log")
            // Only the last worker startup's sanitized errors are useful.
            try Data().write(to: log, options: .atomic)
            stderr = try FileHandle(forWritingTo: log)
            let process = Process()
            process.executableURL = node
            process.arguments = [backend.appendingPathComponent("runtime/watch.mjs").path, configURL.path, String(ProcessInfo.processInfo.processIdentifier)]
            process.standardInput = FileHandle.nullDevice; process.standardOutput = FileHandle.nullDevice
            process.standardError = stderr
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = [node.deletingLastPathComponent().path, "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", env["PATH"] ?? ""].joined(separator: ":")
            process.environment = env
            try process.run(); worker = process
            logger.info("Quota worker started")
        } catch { snapshot = UsageSnapshot(error: "額度背景程序無法啟動：\(error.localizedDescription)") }
    }
    func findNode() -> URL? {
        let env = ProcessInfo.processInfo.environment
        let candidates = [env["GPT_NIANG_NODE"], resources.appendingPathComponent("node").path,
                          "/opt/homebrew/opt/node@22/bin/node", "/opt/homebrew/bin/node", "/usr/local/bin/node"]
            .compactMap { $0 } + (env["PATH"] ?? "").split(separator: ":").map { String($0) + "/node" }
        return candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }).map { URL(fileURLWithPath: $0) }
    }
    func refresh() {
        refreshing = true; refreshUntil = Date().addingTimeInterval(22)
        let wasOpen = bubble
        showQuota()
        if !wasOpen { return }
        do { try Data(UUID().uuidString.utf8).write(to: dataDirectory.appendingPathComponent("refresh.flag"), options: .atomic) }
        catch { settingsError = "無法要求刷新：\(error.localizedDescription)"; refreshing = false }
    }
    func writePresence(visible: Bool) {
        try? writeJSON(["visible": visible, "at": Date().timeIntervalSince1970 * 1000,
                        "pid": ProcessInfo.processInfo.processIdentifier], to: dataDirectory.appendingPathComponent("presence.json"))
    }
    func savePreferences() {
        try? writeJSON(["scale": scale, "volume": volume, "followCodex": followCodex, "loginRequested": loginRequested, "x": x, "y": y,
                        "colorMode": colorMode.rawValue, "fullChance": fullChance, "textChance": textChance,
                        "colorPaused": colorPaused, "specialQuotes": specialQuotes, "bubbleTapAdvance": bubbleTapAdvance],
                       to: dataDirectory.appendingPathComponent("preferences.json"))
    }
    func showQuota() {
        let opening = !bubble
        let switching = message != nil
        message = nil; bubble = true
        updateAppearance()
        restartTTL(delay: opening ? 0.52 : switching ? 0.28 : 0)
        if opening { requestRefreshFlag() }
    }
    func characterClick() {
        if bubble && bubbleTapAdvance { clickBubble() } else { showQuota() }
    }
    private func requestRefreshFlag() {
        try? Data(UUID().uuidString.utf8).write(to: dataDirectory.appendingPathComponent("refresh.flag"), options: .atomic)
    }
    func showQuote() {
        let opening = !bubble
        loadQuotes()
        message = QuoteFile.choose(quotes, excluding: lastQuote) ?? "我在這裡，慢慢來就好。"
        lastQuote = message; bubble = true
        updateAppearance()
        restartTTL(delay: opening ? 0.52 : 0.28)
    }
    func updateAppearance() {
        colorScope = Appearance.scope(mode: colorMode, quote: bubble ? message : nil,
                                      special: specialQuotes.components(separatedBy: "\n"),
                                      fullChance: fullChance, textChance: textChance, draw: Double.random(in: 0..<1))
    }
    private func restartTTL(delay: Double) {
        quoteGeneration += 1
        sceneStarted = Date().addingTimeInterval(delay)
        let generation = quoteGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 5) { [weak self] in
            guard let self, self.quoteGeneration == generation else { return }
            self.bubble = false; self.updateAppearance()
        }
    }
    func clickBubble() {
        if message == nil { showQuote() } else { quoteGeneration += 1; bubble = false; updateAppearance() }
    }
    func loadQuotes() {
        let builtin = (try? Data(contentsOf: resources.appendingPathComponent("quotes.json"))).flatMap { try? QuoteFile.decode($0) } ?? []
        let file = dataDirectory.appendingPathComponent("quotes.json")
        if FileManager.default.fileExists(atPath: file.path) {
            if let data = try? Data(contentsOf: file), let custom = try? QuoteFile.decode(data), !custom.isEmpty { quotes = custom }
            else { quotes = builtin; settingsError = "自訂語錄無法讀取，暫時使用內建語錄。" }
        } else { quotes = builtin }
        quoteText = quotes.map(\.text).joined(separator: "\n")
    }
    func saveQuotes() {
        let rows = quoteText.split(separator: "\n").map { Quote(text: String($0).trimmingCharacters(in: .whitespaces)) }
        guard !rows.isEmpty, rows.allSatisfy(\.valid) else { settingsError = "每行一則語錄，每則最多 200 字，至少保留一則。"; return }
        do {
            try writeJSON(["version": 1, "quotes": rows.map { ["text": $0.text, "weight": $0.weight] as [String: Any] }],
                          to: dataDirectory.appendingPathComponent("quotes.json"))
            quotes = rows; settingsError = nil
        } catch { settingsError = error.localizedDescription }
    }
    func resetQuotes() {
        try? FileManager.default.removeItem(at: dataDirectory.appendingPathComponent("quotes.json")); loadQuotes()
    }
    func play(_ name: String) {
        guard volume > 0, let sound = NSSound(contentsOf: resources.appendingPathComponent(name + ".wav"), byReference: false) else { return }
        sounds.removeAll { !$0.isPlaying }; sounds.append(sound)
        sound.volume = Float(volume); sound.play()
    }
    private func writeJSON(_ values: [String: Any], to file: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: values, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: file, options: .atomic)
    }
}
