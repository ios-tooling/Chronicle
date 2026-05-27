import SwiftUI

/// Detail screen showing full information for a logged error.
@available(iOS 17, macOS 14, *)
struct ErrorLogDetailScreen: View {
    let error: ErrorLog

    var body: some View {
        List {
            overviewSection
            descriptionSection
            if error.userInfo != nil || error.context != nil { contextSection }
            if error.callStackSymbols != nil { callStackSection }
            sourceSection
        }
        .navigationTitle("Error Detail")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if ChronicleDebugger.isAttached {
                ToolbarItem(placement: .automatic) {
                    Button("Log") { logError() }
                }
            }
        }
    }

    private func logError() {
        var lines: [String] = []
        lines.append("═══════════════════════════════════════")
        lines.append("  [\(error.severity.rawValue.uppercased())] \(error.errorType)")
        lines.append("  \(error.timestamp.chronicle_formatted)")
        lines.append("═══════════════════════════════════════")
        lines.append("Domain: \(error.domain)" + (error.code.map { "  Code: \($0)" } ?? ""))
        lines.append("Message: \(error.message)")
        if let reason = error.failureReason       { lines.append("Reason: \(reason)") }
        if let suggestion = error.recoverySuggestion { lines.append("Suggestion: \(suggestion)") }
        if error.fullDescription != error.message {
            lines.append("")
            lines.append("── Full Description ──")
            lines.append(error.fullDescription)
        }
        if let context = error.context, !context.isEmpty {
            lines.append("")
            lines.append("── Context ──")
            for key in context.keys.sorted() { lines.append("  \(key): \(context[key]!)") }
        }
        if let userInfo = error.userInfo, !userInfo.isEmpty {
            lines.append("")
            lines.append("── User Info ──")
            for key in userInfo.keys.sorted() { lines.append("  \(key): \(userInfo[key] ?? "")") }
        }
        if let file = error.sourceFile, let line = error.sourceLine {
            lines.append("")
            lines.append("── Source ──")
            lines.append("  \(file):\(line)" + (error.sourceFunction.map { "  \($0)" } ?? ""))
        }
        if let symbols = error.callStackSymbols {
            lines.append("")
            lines.append("── Call Stack ──")
            symbols.forEach { lines.append("  \($0)") }
        }
        lines.append("═══════════════════════════════════════")
        print(lines.joined(separator: "\n"))
    }

    private var overviewSection: some View {
        Section("Overview") {
            row("Type", error.errorType)
            row("Severity", error.severity.rawValue.capitalized)
            row("Domain", error.domain)
            if let code = error.code { row("Code", "\(code)") }
            row("Timestamp", error.timestamp.chronicle_formatted)
            if let id = error.linkedNetworkLogID {
                row("Linked Network Log", id.uuidString)
            }
        }
    }

    private var descriptionSection: some View {
        Section("Description") {
            Text(error.message).textSelection(.enabled)
            if let reason = error.failureReason {
                row("Failure Reason", reason)
            }
            if let suggestion = error.recoverySuggestion {
                row("Recovery Suggestion", suggestion)
            }
            if error.fullDescription != error.message {
                DisclosureGroup("Full Description") {
                    Text(error.fullDescription)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
    }

    @ViewBuilder
    private var contextSection: some View {
        Section("Context") {
            if let context = error.context {
                ForEach(context.dictionary.keys.sorted(), id: \.self) { key in
                    row(key, "\(context.dictionary[key]!)")
                }
            }
            if let userInfo = error.userInfo, !userInfo.isEmpty {
                DisclosureGroup("User Info") {
                    ForEach(userInfo.keys.sorted(), id: \.self) { key in
                        HStack(alignment: .top) {
                            Text(key).font(.caption.monospaced()).foregroundStyle(.secondary)
                            Spacer()
                            Text(userInfo[key] ?? "").font(.caption.monospaced()).textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var callStackSection: some View {
        if let symbols = error.callStackSymbols {
            Section("Call Stack") {
                DisclosureGroup("Stack Trace (\(symbols.count) frames)") {
                    ForEach(Array(symbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption2.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sourceSection: some View {
        if error.sourceFile != nil || error.sourceFunction != nil {
            Section("Source") {
                if let file = error.sourceFile, let line = error.sourceLine {
                    monoRow("Location", "\(file):\(line)")
                }
                if let function = error.sourceFunction {
                    monoRow("Function", function)
                }
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing).textSelection(.enabled)
        }
    }

    private func monoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.footnote.monospaced()).multilineTextAlignment(.trailing).textSelection(.enabled)
        }
    }
}
