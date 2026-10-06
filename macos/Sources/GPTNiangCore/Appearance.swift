import Foundation

public enum ColorMode: String, CaseIterable, Codable {
    case original, mixed, linked, rainbow, surprise, rare, special
    public var title: String {
        switch self {
        case .original: return "原色"
        case .mixed: return "混合隨機"
        case .linked: return "按語錄配色"
        case .rainbow: return "彩虹流光"
        case .surprise: return "特殊語錄 + 隨機"
        case .rare: return "隨機變色"
        case .special: return "僅特殊語錄"
        }
    }
}
public enum ColorScope: String { case none, text, full }
public enum Appearance {
    public static func scope(mode: ColorMode, quote: String?, special: [String], fullChance: Double, textChance: Double, draw: Double) -> ColorScope {
        if mode == .original { return .none }
        if mode == .linked || mode == .rainbow { return .full }
        guard let quote else { return .none }
        let match = special.contains(quote)
        if mode == .special { return match ? .full : .none }
        if mode == .surprise && match { return .full }
        if draw < fullChance / 100 { return .full }
        if mode == .mixed && draw < (fullChance + textChance) / 100 { return .text }
        return .none
    }
    public static func palette(for text: String, rainbow: Bool = false) -> [String] {
        func matches(_ pattern: String) -> Bool { text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil }
        let models = ["Claude|克劳德|克勞德", "Gemini|双子|雙子", "DeepSeek|鲸|鯨|肥鱼|肥魚|白饭|白飯", "GPT|ChatGPT"].filter(matches).count
        if rainbow || models >= 2 { return colors["rainbow"]! }
        for (name, pattern) in [("claude", "Claude|克劳德|克勞德|压缩|壓縮|失忆|失憶|重构|重構"),
                                ("gemini", "Gemini|双子|雙子|吃醋|竞品|競品"),
                                ("deepsea", "DeepSeek|鲸|鯨|肥鱼|肥魚|白饭|白飯|接住|等等"),
                                ("creeper", "苦力怕|甘蔗|土豆|打怪|存档|存檔|嘶——|屠龙|屠龍"),
                                ("token", "token|额度|額度|余额|餘額|充值")] {
            if matches(pattern) { return colors[name]! }
        }
        return colors["rainbow"]!
    }
    private static let colors = [
        "creeper": ["45986A", "90A84B", "58A897", "749E69", "B3AA54", "45986A"],
        "token": ["D39B28", "E97869", "C9609E", "956CDA", "E49B41", "D39B28"],
        "deepsea": ["368CCA", "37B5BD", "548BE0", "826BC5", "47B2CC", "368CCA"],
        "claude": ["C17A4C", "D89864", "CA776B", "B06F96", "DEAA70", "C17A4C"],
        "gemini": ["507BDB", "8370E4", "BE74CF", "529AD9", "57B5B2", "507BDB"],
        "rainbow": ["D773AD", "9A79DC", "579DCF", "43AE94", "DBA15C", "D773AD"]
    ]
}
