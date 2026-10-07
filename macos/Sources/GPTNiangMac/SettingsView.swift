import SwiftUI
import ServiceManagement
import GPTNiangCore

struct SettingsView: View {
    @ObservedObject var model: WidgetModel
    @State private var loginError: String?

    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("GPT 娘").font(.system(size: 27, weight: .semibold, design: .rounded))
                Text("macOS · \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")").font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            Text("讓小龍娘陪你掌握 Codex 額度。").foregroundStyle(.secondary)
            GroupBox("外觀與顯示") {
                VStack(alignment: .leading, spacing: 14) {
                    HStack { Text("角色大小").frame(width: 70, alignment: .leading); Slider(value: $model.scale, in: 0.6...1.5); Text("\(Int(model.scale * 100))% ").monospacedDigit().frame(width: 48) }
                    HStack { Text("提示音量").frame(width: 70, alignment: .leading); Slider(value: $model.volume, in: 0...1); Text(model.volume == 0 ? "靜音" : "\(Int(model.volume * 100))% ").frame(width: 48) }
                    Toggle("跟隨 Codex 主視窗", isOn: $model.followCodex)
                    Text("關閉後，掛件會固定在桌面；開啟時，Codex 隱藏或最小化後掛件也會隱藏。")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    if let note = model.trackingNote { Text(note).font(.caption).foregroundStyle(.orange) }
                    Toggle("登入 Mac 時自動開啟", isOn: $model.loginRequested)
                        .onChange(of: model.loginRequested) { value in
                            do {
                                if value { try SMAppService.mainApp.register() }
                                else { try SMAppService.mainApp.unregister() }
                                model.savePreferences()
                                loginError = nil
                                if SMAppService.mainApp.status == .requiresApproval { loginError = "請在系統設定的「登入項目」允許 GPT 娘。" }
                            } catch { loginError = "登入項目設定失敗：\(error.localizedDescription)" }
                        }
                    if let loginError { Text(loginError).font(.caption).foregroundStyle(.orange) }
                }.padding(10)
            }
            GroupBox("原版流光效果") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("配色模式", selection: $model.colorMode) {
                        ForEach(ColorMode.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Toggle("暫停流光", isOn: $model.colorPaused)
                    HStack { Text("全身變色機率"); Slider(value: $model.fullChance, in: 0...100); Text(String(format: "%.1f%%", model.fullChance)).frame(width: 55) }
                    HStack { Text("僅文字變色機率"); Slider(value: $model.textChance, in: 0...100); Text(String(format: "%.1f%%", model.textChance)).frame(width: 55) }
                    TextField("特殊語錄（以換行分隔）", text: $model.specialQuotes)
                    Toggle("點角色時也切換語錄／收起氣泡", isOn: $model.bubbleTapAdvance)
                }.padding(10)
            }
            GroupBox("自訂語錄 · 每行一則") {
                VStack(alignment: .leading, spacing: 10) {
                    TextEditor(text: $model.quoteText).font(.system(size: 13)).frame(height: 145)
                        .scrollContentBackground(.hidden).padding(4)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                    HStack {
                        Button("還原內建語錄") { model.resetQuotes() }
                        Spacer()
                        Button("儲存語錄") { model.saveQuotes() }.buttonStyle(.borderedProminent)
                    }
                }.padding(10)
            }
            if let error = model.settingsError { Text(error).font(.caption).foregroundStyle(.orange) }
            HStack {
                Button("開啟資料目錄") { NSWorkspace.shared.open(model.dataDirectory) }
                Spacer()
                Button("重設位置") { model.x = 1; model.y = 0; model.savePreferences() }
                Button("刷新額度") { model.refresh() }
            }
            Text("額度可見時每 60 秒更新。使用目前 Codex 登入，不建立聊天或呼叫模型。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24) }.frame(width: 500, height: 700)
        .onChange(of: model.scale) { _ in model.savePreferences() }
        .onChange(of: model.volume) { _ in model.savePreferences() }
        .onChange(of: model.colorMode) { _ in model.updateAppearance(); model.savePreferences() }
        .onChange(of: model.fullChance) { _ in model.updateAppearance(); model.savePreferences() }
        .onChange(of: model.textChance) { _ in model.updateAppearance(); model.savePreferences() }
        .onChange(of: model.colorPaused) { _ in model.savePreferences() }
        .onChange(of: model.specialQuotes) { _ in model.updateAppearance(); model.savePreferences() }
        .onChange(of: model.bubbleTapAdvance) { _ in model.savePreferences() }
        .onChange(of: model.followCodex) { _ in model.savePreferences() }
    }
}
