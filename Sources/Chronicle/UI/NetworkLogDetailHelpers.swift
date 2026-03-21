import SwiftUI

extension NetworkLogDetailScreen {
    func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    func headersView(_ title: String, _ headers: [String: String]) -> some View {
        DisclosureGroup(title) {
            ForEach(headers.keys.sorted(), id: \.self) { key in
                HStack(alignment: .top) {
                    Text(key)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(headers[key] ?? "")
                        .font(.caption.monospaced())
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
            }
        }
    }

    func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: .green
        case 300..<400: .orange
        default: .red
        }
    }
}
