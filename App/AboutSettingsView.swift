import AppKit
import DesignSystem
import SwiftUI
import Updates

struct AboutSettingsView: View {
    private static let sourceCodeURL = url("https://github.com/alekseylopukh/clipsy")
    private static let issueURL = url("https://github.com/alekseylopukh/clipsy/issues/new")
    private static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    private static let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""

    @Environment(AppUpdater.self) private var updater
    @State private var isShowingAcknowledgements = false
    @State private var updateError: String?

    var body: some View {
        Form {
            Section {
                VStack(spacing: DesignTokens.spacingMedium) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: DesignTokens.aboutIconSize, height: DesignTokens.aboutIconSize)
                        .accessibilityHidden(true)
                    Text("Clipsy")
                        .font(.title2.bold())
                    Text("Version \(Self.version) (\(Self.build))")
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Text("Free and open-source under GPL-3.0")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Section {
                Link("Source Code", destination: Self.sourceCodeURL)
                Link("Report an Issue", destination: Self.issueURL)
                Button("Acknowledgements") {
                    isShowingAcknowledgements = true
                }
                .buttonStyle(.link)
            }

            if updater.isAvailable {
                Section {
                    Toggle(
                        "Automatically check for updates",
                        isOn: Binding(get: { updater.automaticallyChecksForUpdates }, set: setAutomaticChecks)
                    )
                    LabeledContent {
                        Button("Check for Updates…", action: checkForUpdates)
                    } label: {
                        EmptyView()
                    }
                } header: {
                    Text("Updates")
                } footer: {
                    FormFootnote(Text(
                        "Clipsy looks for a new version on GitHub only when you check or turn on automatic checks."
                    ))
                }
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
        .sheet(isPresented: $isShowingAcknowledgements) {
            AcknowledgementsView()
        }
        .alert(
            "Clipsy can’t check for updates.",
            isPresented: Binding(get: { updateError != nil }, set: {
                if !$0 {
                    updateError = nil
                }
            }),
            presenting: updateError
        ) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    private func setAutomaticChecks(_ isOn: Bool) {
        do {
            try updater.setAutomaticallyChecksForUpdates(isOn)
        } catch {
            updateError = error.localizedDescription
        }
    }

    private func checkForUpdates() {
        do {
            try updater.checkForUpdates()
        } catch {
            updateError = error.localizedDescription
        }
    }

    private static func url(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            fatalError("\(string) is a valid URL literal")
        }
        return url
    }
}
