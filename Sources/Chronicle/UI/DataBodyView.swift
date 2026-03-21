import SwiftUI

/// Displays raw bytes or formatted JSON for a Data payload, inside a collapsible disclosure group.
struct DataBodyView: View {
    let title: String
    let data: Data
    @State private var showRaw = false

    var body: some View {
        Section {
            DisclosureGroup(title) {
                Picker("Format", selection: $showRaw) {
                    Text("Formatted").tag(false)
                    Text("Raw").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    if showRaw {
                        rawView
                    } else {
                        formattedView
                    }
                }
            }
        }
    }

    private var formattedView: some View {
        Group {
            if let json = prettyJSON {
                Text(json)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            } else if let text = String(data: data, encoding: .utf8) {
                Text(text)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            } else {
                Text("\(data.count) bytes (binary)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var rawView: some View {
        let text = String(data: data, encoding: .utf8) ?? data.map { String(format: "%02x ", $0) }.joined()
        return Text(text)
            .font(.footnote.monospaced())
            .textSelection(.enabled)
    }

    private var prettyJSON: String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: pretty, encoding: .utf8) else { return nil }
        return str
    }
}
