import SwiftUI

/// A navigation link to view a data payload's contents.
@available(iOS 17, macOS 14, *)
struct DataBodyView: View {
    let title: String
    let data: Data

    var body: some View {
        NavigationLink {
            DataBodyScreen(title: title, data: data)
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
