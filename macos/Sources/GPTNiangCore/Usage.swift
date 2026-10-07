import Foundation

public struct QuotaWindow: Codable, Equatable, Identifiable {
    public let minutes: Int
    public let remaining: Double
    public let resetsAt: Double?
    public var id: Int { minutes }
    public var title: String {
        if minutes == 300 { return "5 小時" }
        if minutes == 10080 { return "每週" }
        if minutes % 1440 == 0 { return "\(minutes / 1440) 天" }
        if minutes % 60 == 0 { return "\(minutes / 60) 小時" }
        return "\(minutes) 分鐘"
    }

    public init(minutes: Int, remaining: Double, resetsAt: Double? = nil) {
        self.minutes = minutes; self.remaining = remaining; self.resetsAt = resetsAt
    }
    public func expired(at date: Date) -> Bool {
        guard let resetsAt, resetsAt.isFinite, resetsAt > 0 else { return false }
        return resetsAt <= date.timeIntervalSince1970
    }
    public func resetText(at date: Date, timeZone: TimeZone = .current, countdown: Bool? = nil) -> String {
        guard let resetsAt, resetsAt.isFinite, resetsAt > 0, resetsAt <= 253402271999 else { return "未提供重置時間" }
        let interval = resetsAt - date.timeIntervalSince1970
        if interval <= 0 { return "等待更新後的額度" }
        if countdown == true && interval >= 86400 {
            let hours = Int(ceil(interval / 3600))
            return "\(hours / 24) 天 \(hours % 24) 小時後重置"
        }
        if countdown != false && interval < 86400 {
            let minutes = max(1, Int(ceil(interval / 60)))
            return minutes >= 60 ? "\(minutes / 60) 小時 \(minutes % 60) 分鐘後重置" : "\(minutes) 分鐘後重置"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_HK")
        formatter.timeZone = timeZone
        formatter.dateFormat = "M/d HH:mm"
        return "\(formatter.string(from: Date(timeIntervalSince1970: resetsAt))) 重置"
    }
}

public struct UsageSnapshot: Decodable {
    public let ok: Bool
    public let queryOk: Bool?
    public let observedAt: Double?
    public let windows: [QuotaWindow]
    public let error: String?
    public let plan: String?
    public let planLabel: String?

    public init(ok: Bool = false, queryOk: Bool? = false, observedAt: Double? = nil, windows: [QuotaWindow] = [], error: String? = nil, plan: String? = nil, planLabel: String? = nil) {
        self.ok = ok; self.queryOk = queryOk; self.observedAt = observedAt; self.windows = windows; self.error = error
        self.plan = plan; self.planLabel = planLabel
    }
    public func stale(at date: Date) -> Bool {
        guard ok, queryOk != false, let observedAt, observedAt.isFinite else { return true }
        let age = date.timeIntervalSince1970 * 1000 - observedAt
        return age > 180000 || age < -5000
    }
}

public struct Quote: Decodable, Equatable {
    public let text: String
    public let weight: Double
    public init(text: String, weight: Double = 1) { self.text = text; self.weight = weight }
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(), let text = try? container.decode(String.self) {
            self.init(text: text); return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(text: try container.decode(String.self, forKey: .text),
                  weight: try container.decodeIfPresent(Double.self, forKey: .weight) ?? 1)
    }
    private enum CodingKeys: String, CodingKey { case text, weight }
    public var valid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= 200 &&
        weight.isFinite && weight > 0 && weight <= 1000 &&
        !text.unicodeScalars.contains { $0.value < 32 && ![9, 10, 13].contains($0.value) }
    }
}

public enum QuoteFile {
    private struct Envelope: Decodable { let quotes: [Quote] }
    public static func decode(_ data: Data) throws -> [Quote] {
        // Windows' editable JSON may include a UTF-8 BOM.
        let content = data.starts(with: [0xEF, 0xBB, 0xBF]) ? data.dropFirst(3) : data[...]
        let decoder = JSONDecoder()
        let quotes: [Quote]
        if let envelope = try? decoder.decode(Envelope.self, from: content) { quotes = envelope.quotes }
        else { quotes = try decoder.decode([Quote].self, from: content) }
        return quotes.filter(\.valid)
    }
    public static func choose(_ quotes: [Quote], excluding previous: String?, draw: Double = Double.random(in: 0..<1)) -> String? {
        let valid = quotes.filter(\.valid)
        let different = valid.filter { $0.text != previous }
        let candidates = different.isEmpty ? valid : different
        guard let last = candidates.last else { return nil }
        var target = min(1, max(0, draw)) * candidates.reduce(0) { $0 + $1.weight }
        for quote in candidates { target -= quote.weight; if target < 0 { return quote.text } }
        return last.text
    }
}
