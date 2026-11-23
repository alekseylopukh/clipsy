import AppKit
import DesignSystem

final class ShelfPanel: NSPanel, NSWindowDelegate {
    var onCancel: () -> Void = {}
    var onResignKey: () -> Void = {}
    var onKeyDown: (NSEvent) -> Bool = { _ in false }
    var onFlagsChanged: (NSEvent) -> Void = { _ in }

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        isMovable = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        animationBehavior = .none
        sharingType = .none
        delegate = self
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func cancelOperation(_: Any?) {
        onCancel()
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .scrollWheel, let contentView,
           let redirect = WheelRedirect.horizontalEvent(for: event, in: contentView)
        {
            redirect.scrollView.scrollWheel(with: redirect.event)
            return
        }
        super.sendEvent(event)
    }

    override func keyDown(with event: NSEvent) {
        if !onKeyDown(event) {
            super.keyDown(with: event)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        onFlagsChanged(event)
        super.flagsChanged(with: event)
    }

    override func resignKey() {
        super.resignKey()
        onResignKey()
    }

    func window(_: NSWindow, willPositionSheet _: NSWindow, using rect: NSRect) -> NSRect {
        rect.offsetBy(dx: 0, dy: -DesignTokens.shelfShadowMargin)
    }
}
