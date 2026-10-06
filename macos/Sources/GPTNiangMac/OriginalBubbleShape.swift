import SwiftUI

struct OriginalBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 283, y: 85))
        arc(&path, from: CGPoint(x: 283, y: 85), to: CGPoint(x: 27, y: 85), rx: 128, ry: 79, large: true)
        arc(&path, from: CGPoint(x: 27, y: 85), to: CGPoint(x: 114, y: 160), rx: 128, ry: 79)
        arc(&path, from: CGPoint(x: 114, y: 160), to: CGPoint(x: 149, y: 164), rx: 20, ry: 10)
        arc(&path, from: CGPoint(x: 149, y: 164), to: CGPoint(x: 283, y: 85), rx: 128, ry: 79)
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: rect.width / 350, y: rect.height / 239))
    }
    // SVG endpoint-to-center conversion for the unrotated, sweep=0 XAML arcs.
    private func arc(_ path: inout Path, from a: CGPoint, to b: CGPoint, rx: CGFloat, ry: CGFloat, large: Bool = false) {
        let dx = (a.x - b.x) / 2, dy = (a.y - b.y) / 2
        let numerator = max(0, rx * rx * ry * ry - rx * rx * dy * dy - ry * ry * dx * dx)
        let denominator = rx * rx * dy * dy + ry * ry * dx * dx
        let factor = (large ? 1.0 : -1.0) * sqrt(numerator / max(0.000001, denominator))
        let cx = factor * rx * dy / ry + (a.x + b.x) / 2
        let cy = -factor * ry * dx / rx + (a.y + b.y) / 2
        let start = atan2((a.y - cy) / ry, (a.x - cx) / rx)
        var delta = atan2((b.y - cy) / ry, (b.x - cx) / rx) - start
        if delta > 0 { delta -= 2 * .pi }
        for step in 1...80 {
            let angle = start + delta * Double(step) / 80
            path.addLine(to: CGPoint(x: cx + rx * cos(angle), y: cy + ry * sin(angle)))
        }
    }
}
