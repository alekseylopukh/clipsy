import AppKit
import SwiftUI
import Testing
@testable import ShelfUI

@MainActor
struct WheelRedirectTests {
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

    @Test(arguments: [CGScrollEventUnit.line, .pixel])
    func `a wheel turn over the strip becomes the same horizontal one`(units: CGScrollEventUnit) throws {
        let host = try Self.strip()
        let wheelEvent = try #require(NSEvent(cgEvent: Self.wheel(vertical: -3, units: units, at: Self.overStrip)))

        let (scrollView, redirected) = try #require(WheelRedirect.horizontalEvent(for: wheelEvent, in: host))

        #expect(scrollView === Self.find(in: host))

        #expect(redirected.scrollingDeltaX == wheelEvent.scrollingDeltaY)
        #expect(redirected.scrollingDeltaY == 0)
        #expect(redirected.hasPreciseScrollingDeltas == wheelEvent.hasPreciseScrollingDeltas)
    }

    @Test func `a trackpad gesture over the strip is left alone`() throws {
        let host = try Self.strip()
        let gesture = try Self.wheel(vertical: -3, units: .pixel, at: Self.overStrip)
        gesture.setIntegerValueField(.scrollWheelEventScrollPhase, value: Int64(NSEvent.Phase.changed.rawValue))
        let gestureEvent = try #require(NSEvent(cgEvent: gesture))

        #expect(WheelRedirect.horizontalEvent(for: gestureEvent, in: host) == nil)
    }

    private static var overStrip: CGPoint {
        // an event without a window reports its screen location, flipped against the main display
        CGPoint(x: 200, y: CGDisplayBounds(CGMainDisplayID()).height - 50)
    }

    private static func strip() throws -> NSView {
        try host(ScrollView(.horizontal) {
            Color.red.frame(width: 2000, height: 100)
        }).0
    }

    private static func wheel(vertical: Int32, units: CGScrollEventUnit, at point: CGPoint) throws -> CGEvent {
        let event = try #require(CGEvent(
            scrollWheelEvent2Source: nil, units: units, wheelCount: 2, wheel1: vertical, wheel2: 0, wheel3: 0
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
