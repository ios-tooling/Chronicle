import SwiftUI

/// A button that presents the ChronicleScreen in a sheet.
@available(iOS 17, macOS 14, *)
public struct ChronicleButton<Content: View>: View {
	@State private var isPresented = false
	let content: () -> Content
	
	public init(content: @escaping () -> Content) {
		self.content = content
	}
	
	public var body: some View {
		Button { isPresented = true } label: {
			content()
				.contentShape(.rect)
		}
		.sheet(isPresented: $isPresented) {
			ChronicleScreen()
		}
	}
}

@available(iOS 17, macOS 14, *)
extension ChronicleButton where Content == ChronicleButtonLabel {
	public init() {
		self.init { ChronicleButtonLabel() }
	}
}

public struct ChronicleButtonLabel: View {
	public var body: some View {
		Label("Chronicle", systemImage: "clock.arrow.circlepath")
	}
}
