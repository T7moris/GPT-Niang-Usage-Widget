import XCTest
@testable import GPTNiangCore

final class WindowFollowCadenceTests: XCTestCase {
    func testFastPositionTicksDoNotRepeatFullDiscovery() {
        var cadence = WindowFollowCadence()
        XCTAssertTrue(cadence.discover(now: 0))
        for tick in 1..<15 { XCTAssertFalse(cadence.discover(now: Double(tick) / 60)) }
        XCTAssertTrue(cadence.discover(now: 0.25))
        XCTAssertTrue(cadence.discover(now: 0.26, force: true))
        XCTAssertFalse(cadence.discover(now: 0.27))
    }

    func testVisibilityChangesWriteImmediatelyBetweenHeartbeats() {
        var cadence = WindowFollowCadence()
        XCTAssertTrue(cadence.presence(now: 0, visible: true))
        XCTAssertFalse(cadence.presence(now: 0.5, visible: true))
        XCTAssertTrue(cadence.presence(now: 0.6, visible: false))
        XCTAssertTrue(cadence.presence(now: 0.7, visible: true))
        XCTAssertFalse(cadence.presence(now: 1.6, visible: true))
        XCTAssertTrue(cadence.presence(now: 1.7, visible: true))
    }

    func testDiagnosticsHaveAnIndependentLimit() {
        var cadence = WindowFollowCadence()
        XCTAssertTrue(cadence.diagnostics(now: 0))
        XCTAssertTrue(cadence.presence(now: 0, visible: true))
        XCTAssertFalse(cadence.diagnostics(now: 0.1))
        XCTAssertTrue(cadence.diagnostics(now: 0.25))
        XCTAssertFalse(cadence.presence(now: 0.25, visible: true))
    }
}
