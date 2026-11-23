import AppKit

@MainActor
enum WheelRedirect {
    /// the event has no window, so deliver it to the returned scroll view, not through a window hit test
    static func horizontalEvent(
        for event: NSEvent,
        in contentView: NSView
    ) -> (scrollView: NSScrollView, event: NSEvent)? {
        guard event.type == .scrollWheel, event.phase.isEmpty, event.momentumPhase.isEmpty,
              event.scrollingDeltaX == 0, event.scrollingDeltaY != 0,
              let scrollView = contentView.hitTest(event.locationInWindow)?.enclosingScrollView,
              scrollsOnlyHorizontally(scrollView),
              let source = event.cgEvent
        else { return nil }
        // the precise delta lives in private CGEvent fields, so a field swap loses it; build a fresh event instead
        let precise = event.hasPreciseScrollingDeltas
        let delta = precise
            ? Int32(event.scrollingDeltaY.rounded())
            : Int32(truncatingIfNeeded: source.getIntegerValueField(.scrollWheelEventDeltaAxis1))
        guard delta != 0,
              let wheel = CGEvent(
                  scrollWheelEvent2Source: nil, units: precise ? .pixel : .line,
                  wheelCount: 2, wheel1: 0, wheel2: delta, wheel3: 0
              )
        else { return nil }
        wheel.location = source.location
        wheel.flags = source.flags
        wheel.timestamp = source.timestamp
        guard let horizontal = NSEvent(cgEvent: wheel) else { return nil }
        return (scrollView, horizontal)
    }

    /// SwiftUI turns off vertical elasticity on a horizontal-only ScrollView; sizes alone fail with legacy scrollers
    static func scrollsOnlyHorizontally(_ scrollView: NSScrollView) -> Bool {
        guard let document = scrollView.documentView else { return false }
        return document.frame.width > scrollView.contentView.bounds.width
            && scrollView.verticalScrollElasticity == .none
    }
}
