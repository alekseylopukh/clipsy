import AppKit
import SwiftUI
import Testing
@testable import ShelfUI

@MainActor
struct WheelRedirectTests {
    @Test func `a vertical wheel turn becomes the same horizontal one`() throws {
        let event = try Self.wheel(vertical: -3)

        WheelRedirect.swapAxes(of: event)

        #expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis1) == 0)
        #expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis2) == -3)
        let swapped = try #require(NSEvent(cgEvent: event))
        #expect(swapped.scrollingDeltaY == 0)
        #expect(swapped.scrollingDeltaX != 0)
    }

    @Test(arguments: [NSScroller.Style.overlay, .legacy], [false, true])
    func `a SwiftUI strip that overflows sideways scrolls only horizontally`(
        style: NSScroller.Style,
        hidesIndicators: Bool
    ) throws {
        let (_, scrollView) = try Self.host(ScrollView(.horizontal) {
            Color.red.frame(width: 2000, height: 100)
        }.scrollIndicators(hidesIndicators ? .hidden : .automatic), style: style)

        #expect(WheelRedirect.scrollsOnlyHorizontally(scrollView))
    }

    @Test func `a vertical scroll view is left alone`() throws {
        let (_, scrollView) = try Self.host(ScrollView(.vertical) {
            Color.red.frame(width: 400, height: 2000)
        })

        #expect(WheelRedirect.scrollsOnlyHorizontally(scrollView) == false)
    }

    @Test func `a strip whose cards all fit is left alone`() throws {
        let (_, scrollView) = try Self.host(ScrollView(.horizontal) {
            Color.red.frame(width: 200, height: 100)
        })

        #expect(WheelRedirect.scrollsOnlyHorizontally(scrollView) == false)
    }

    @Test func `a wheel turn over the strip is redirected, a trackpad gesture is not`() throws {
        let (host, _) = try Self.host(ScrollView(.horizontal) {
            Color.red.frame(width: 2000, height: 100)
        })
        // an event without a window reports its screen location, flipped against the main display
        let point = CGPoint(x: 200, y: CGDisplayBounds(CGMainDisplayID()).height - 50)
        let wheel = try Self.wheel(vertical: -3, at: point)
        let gesture = try Self.wheel(vertical: -3, at: point)
        gesture.setIntegerValueField(.scrollWheelEventScrollPhase, value: Int64(NSEvent.Phase.changed.rawValue))

        let wheelEvent = try #require(NSEvent(cgEvent: wheel))
        let gestureEvent = try #require(NSEvent(cgEvent: gesture))
        let redirected = try #require(WheelRedirect.horizontalEvent(for: wheelEvent, in: host))
        let passed = WheelRedirect.horizontalEvent(for: gestureEvent, in: host)

        #expect(redirected.scrollingDeltaX != 0)
        #expect(redirected.scrollingDeltaY == 0)
        #expect(passed == nil)
    }

    private static func wheel(vertical: Int32, at point: CGPoint = .zero) throws -> CGEvent {
        let event = try #require(CGEvent(
            scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: vertical, wheel2: 0, wheel3: 0
        ))
        event.location = point
        return event
    }

    private static func host(
        _ content: some View,
        style: NSScroller.Style = .overlay
    ) throws -> (NSView, NSScrollView) {
        let host = NSHostingView(rootView: content.frame(width: 400, height: 100))
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 400, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        let scrollView = try #require(find(in: host))
        scrollView.scrollerStyle = style
        host.layoutSubtreeIfNeeded()
        return (host, scrollView)
    }

    private static func find(in view: NSView) -> NSScrollView? {
        if let scrollView = view as? NSScrollView {
            return scrollView
        }
        return view.subviews.lazy.compactMap { find(in: $0) }.first
    }
}
