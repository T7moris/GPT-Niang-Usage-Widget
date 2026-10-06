import XCTest
import AppKit
@testable import GPTNiangMac

final class NativeInteractionTests: XCTestCase {
    @MainActor func testNativeSingleDoubleAndRightClickRoutes() async throws {
        // Detached view events exercise routing without posting OS input.
        let view = CharacterInteraction.PointerView()
        var clicks = 0, settings = 0
        var presses: [Bool] = []
        view.onClick = { clicks += 1 }; view.onSettings = { settings += 1 }
        view.onPress = { presses.append($0) }
        func event(_ type: NSEvent.EventType, clicks: Int) -> NSEvent {
            NSEvent.mouseEvent(with: type, location: .zero, modifierFlags: [], timestamp: 0,
                               windowNumber: 0, context: nil, eventNumber: 0, clickCount: clicks, pressure: 0)!
        }
        view.mouseDown(with: event(.leftMouseDown, clicks: 1)); view.mouseUp(with: event(.leftMouseUp, clicks: 1))
        XCTAssertEqual(clicks, 1); XCTAssertEqual(settings, 0); XCTAssertEqual(presses, [true, false])
        view.mouseDown(with: event(.leftMouseDown, clicks: 2)); view.mouseUp(with: event(.leftMouseUp, clicks: 2))
        XCTAssertEqual(settings, 1); XCTAssertEqual(clicks, 1)
        view.rightMouseDown(with: event(.rightMouseDown, clicks: 1)); XCTAssertEqual(settings, 2)
    }
    @MainActor func testSpeedHelperEOFMarksStoppedAndCanRestart() async throws {
        let store = ThreadSpeedStore()
        store.start(executable: URL(fileURLWithPath: "/usr/bin/true"), arguments: [])
        for _ in 0..<30 {
            if store.error != nil { break }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertNotNil(store.error)
        XCTAssertTrue(store.rows.isEmpty)
        store.start(executable: URL(fileURLWithPath: "/bin/cat"), arguments: [])
        XCTAssertNil(store.error)
        store.stop()
        try await Task.sleep(nanoseconds: 30_000_000)
        // A callback from the previous helper must not clear a new run's state.
        XCTAssertNil(store.error)
    }
}
