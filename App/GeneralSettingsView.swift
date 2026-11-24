import DesignSystem
import Pasting
import ServiceManagement
import Store
import SwiftUI

struct GeneralSettingsView: View {
    @Environment(RetentionSettings.self) private var retention
    @Environment(MenuBarSettings.self) private var menuBarSettings
    @Environment(\.appearsActive) private var appearsActive
    @AppStorage(PasteSettings.soundEffectsKey) private var playsSounds = false
    @AppStorage(PasteSettings.behaviorKey) private var pasteBehavior = PasteBehavior.pasteIntoActiveApp
    @AppStorage(PasteSettings.plainTextByDefaultKey) private var pastesPlainText = false
    @State private var loginItemStatus = SMAppService.mainApp.status
    @State private var isAccessibilityTrusted = SystemAccessibilityTrust().isTrusted
    @State private var draftPeriod: RetentionPeriod?
    @State private var isDraggingRetention = false
    @State private var isConfirmingErase = false
    @State private var failure: Failure?

    var body: some View {
        @Bindable var menuBarSettings = menuBarSettings
        Form {
            Section {
                Toggle("Open at login", isOn: Binding(get: { isOpenAtLoginOn }, set: setOpenAtLogin))
                if loginItemStatus == .requiresApproval {
                    LabeledContent {
                        Button("Open Login Items…") {
                            SMAppService.openSystemSettingsLoginItems()
                        }
                    } label: {
                        LabelWithNote(
                            Text("Needs your approval"),
                            note: Text("Allow Clipsy in System Settings › General › Login Items & Extensions.")
                        )
                    }
                }
                Toggle("Show in menu bar", isOn: $menuBarSettings.isItemShown)
                Toggle("Click on menu bar icon opens the Shelf", isOn: $menuBarSettings.clickOpensShelf)
                    .disabled(!menuBarSettings.isItemShown)
                Toggle("Sound effects", isOn: $playsSounds)
            }

            Section("Pasting") {
                Picker("Paste behavior", selection: $pasteBehavior) {
                    Text("Paste into the active app").tag(PasteBehavior.pasteIntoActiveApp)
                    Text("Copy to the clipboard only").tag(PasteBehavior.copyOnly)
                }
                .pickerStyle(.radioGroup)
                Toggle("Paste without formatting by default", isOn: $pastesPlainText)
                AccessibilityStatusRow(isTrusted: isAccessibilityTrusted)
            }

            Section("History") {
                Slider(
                    value: Binding(get: { retentionSliderValue }, set: setRetentionSliderValue),
                    in: 0 ... Double(RetentionPeriod.allCases.count - 1),
                    step: 1,
                    label: { Text("Keep history for") },
                    tick: { SliderTick(RetentionPeriod(sliderValue: $0).title, $0) },
                    onEditingChanged: retentionEditingChanged
                )
                if let summary = retention.storageSummary {
                    StorageSummaryRow(summary: summary)
                }
                LabeledContent {
                    Button("Erase History…", role: .destructive) {
                        isConfirmingErase = true
                    }
                } label: {
                    LabelWithNote(Text("Remove all cards from History"), note: Text("Cards on boards are kept."))
                }
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
        .task(id: appearsActive) {
            if appearsActive {
                refreshSystemStatus()
                await retention.refreshStorageSummary()
            }
        }
        .alert(
            "Remove older cards from History?",
            // the buttons clear the pending change; clearing it here would run before the confirm task
            isPresented: Binding(get: { retention.pendingPeriod != nil }, set: { _ in })
        ) {
            Button("Remove Cards", role: .destructive) {
                perform(failureTitle: String(localized: "Clipsy can’t change how long it keeps history.")) {
                    try await retention.confirmPendingChange()
                }
            }
            Button("Cancel", role: .cancel) {
                retention.cancelPendingChange()
            }
        } message: {
            Text(
                "Cards older than the new limit will be removed from History. Cards on boards are kept. You can’t undo this action."
            )
        }
        .alert("Erase all History?", isPresented: $isConfirmingErase) {
            Button("Erase History", role: .destructive) {
                perform(failureTitle: String(localized: "Clipsy can’t erase the history.")) {
                    try await retention.eraseHistory()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All cards will be removed from History. Cards on boards are kept. You can’t undo this action.")
        }
        .alert(
            failure?.title ?? "",
            isPresented: Binding(get: { failure != nil }, set: {
                if !$0 {
                    failure = nil
                }
            }),
            presenting: failure
        ) { _ in
            Button("OK") {}
        } message: { failure in
            Text(failure.message)
        }
    }

    private var isOpenAtLoginOn: Bool {
        loginItemStatus == .enabled || loginItemStatus == .requiresApproval
    }

    private var retentionSliderValue: Double {
        (draftPeriod ?? retention.pendingPeriod ?? retention.period).sliderValue
    }

    private func setOpenAtLogin(_ isOn: Bool) {
        do {
            if isOn {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            failure = Failure(title: String(localized: "Clipsy can’t change the login item."), error: error)
        }
        loginItemStatus = SMAppService.mainApp.status
    }

    private func setRetentionSliderValue(_ value: Double) {
        draftPeriod = RetentionPeriod(sliderValue: value)
        if !isDraggingRetention {
            commitDraftPeriod()
        }
    }

    private func retentionEditingChanged(_ isEditing: Bool) {
        isDraggingRetention = isEditing
        if !isEditing {
            commitDraftPeriod()
        }
    }

    private func commitDraftPeriod() {
        guard let draftPeriod else { return }
        Task {
            do {
                try await retention.select(draftPeriod)
            } catch {
                failure = Failure(
                    title: String(localized: "Clipsy can’t change how long it keeps history."),
                    error: error
                )
            }
            if self.draftPeriod == draftPeriod {
                self.draftPeriod = nil
            }
        }
    }

    private func refreshSystemStatus() {
        loginItemStatus = SMAppService.mainApp.status
        isAccessibilityTrusted = SystemAccessibilityTrust().isTrusted
    }

    private func perform(failureTitle: String, _ action: @escaping () async throws -> Void) {
        Task {
            do {
                try await action()
            } catch {
                failure = Failure(title: failureTitle, error: error)
            }
        }
    }
}

private struct AccessibilityStatusRow: View {
    let isTrusted: Bool

    var body: some View {
        LabeledContent {
            if isTrusted {
                PermissionStatusLabel(isAllowed: true)
            } else {
                Button("Open System Settings…") {
                    _ = SystemAccessibilityTrust().requestTrust()
                }
            }
        } label: {
            LabelWithNote(
                Text("Accessibility"),
                note: isTrusted
                    ? Text("Clipsy can paste directly into other apps.")
                    : Text("Not allowed. Clipsy copies cards to the clipboard instead of pasting them.")
            )
        }
    }
}

private struct StorageSummaryRow: View {
    let summary: StorageSummary

    var body: some View {
        LabeledContent("Storage") {
            Text(
                "^[\(summary.cardCount) cards](inflect: true), \(summary.byteCount, format: .byteCount(style: .file))"
            )
        }
    }
}

private struct Failure {
    let title: String
    let message: String

    init(title: String, error: any Error) {
        self.title = title
        message = error.localizedDescription
    }
}

private extension RetentionPeriod {
    init(sliderValue: Double) {
        let index = min(max(Int(sliderValue.rounded()), 0), Self.allCases.count - 1)
        self = Self.allCases[index]
    }

    var sliderValue: Double {
        Double(Self.allCases.firstIndex(of: self) ?? 0)
    }
}
