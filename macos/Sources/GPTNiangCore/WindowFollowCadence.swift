import Foundation

// Use monotonic uptime so wall-clock adjustments cannot suspend following.
public struct WindowFollowCadence {
    private var lastDiscovery = -Double.infinity
    private var lastPresence = -Double.infinity
    private var lastDiagnostics = -Double.infinity
    private var visible: Bool?

    public init() {}

    public mutating func discover(now: TimeInterval, force: Bool = false) -> Bool {
        guard force || now - lastDiscovery >= 0.25 else { return false }
        lastDiscovery = now
        return true
    }

    public mutating func presence(now: TimeInterval, visible: Bool) -> Bool {
        guard self.visible != visible || now - lastPresence >= 1 else { return false }
        self.visible = visible
        lastPresence = now
        return true
    }

    public mutating func diagnostics(now: TimeInterval) -> Bool {
        guard now - lastDiagnostics >= 0.25 else { return false }
        lastDiagnostics = now
        return true
    }
}
