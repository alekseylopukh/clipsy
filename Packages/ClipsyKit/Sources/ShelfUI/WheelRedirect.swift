import AppKit

@MainActor
enum WheelRedirect {
    static func horizontalEvent(for event: NSEvent, in contentView: NSView) -> NSEvent? {
        guard event.type == .scrollWheel, event.phase.isEmpty, event.momentumPhase.isEmpty,
              event.scrollingDeltaX == 0, event.scrollingDeltaY != 0,
              let scrollView = contentView.hitTest(event.locationInWindow)?.enclosingScrollView,
              scrollsOnlyHorizontally(scrollView),
              let wheel = event.cgEvent?.copy()
        else { return nil }
        swapAxes(of: wheel)
        return NSEvent(cgEvent: wheel)
    }

    /// SwiftUI turns off vertical elasticity on a horizontal-only ScrollView; sizes alone fail with legacy scrollers
    static func scrollsOnlyHorizontally(_ scrollView: NSScrollView) -> Bool {
        guard let document = scrollView.documentView else { return false }
        return document.frame.width > scrollView.contentView.bounds.width
            && scrollView.verticalScrollElasticity == .none
    }

    static func swapAxes(of event: CGEvent) {
        let pairs: [(CGEventField, CGEventField)] = [
            (.scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2),
            (.scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2),
            (.scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis2)
        ]
        for (vertical, horizontal) in pairs {
            event.setIntegerValueField(horizontal, value: event.getIntegerValueField(vertical))
            event.setIntegerValueField(vertical, value: 0)
        }
    }
}
