import SwiftUI

/// A button that presents the ChronicleScreen in a sheet.
public struct ChronicleButton: View {
    @State private var isPresented = false

    public init() {}

    public var body: some View {
        Button { isPresented = true } label: {
            Label("Chronicle", systemImage: "clock.arrow.circlepath")
        }
        .sheet(isPresented: $isPresented) {
            ChronicleScreen()
        }
    }
}
