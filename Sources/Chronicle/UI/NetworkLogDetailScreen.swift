import SwiftUI

/// Detail screen showing full request and response information for a network log.
@available(iOS 17, macOS 14, *)
struct NetworkLogDetailScreen: View {
	let log: NetworkLog
	
	var body: some View {
		List {
			overviewSection
			requestSection
			responseSection
			metricsSection
			if log.error != nil || log.linkedErrorID != nil {
				errorSection
			}
			sourceSection
		}
		.navigationTitle("Network Detail")
		#if !os(macOS)
				.navigationBarTitleDisplayMode(.inline)
		#endif
		.toolbar {
			if ChronicleDebugger.isAttached {
				ToolbarItem(placement: .automatic) {
					Button("Log") { logTransaction() }
				}
			}
		}
	}

	private func logTransaction() {
		var lines: [String] = []
		lines.append("═══════════════════════════════════════")
		lines.append("  \(log.method) \(log.url.absoluteString)")
		lines.append("  \(log.timestamp.chronicle_formatted)")
		lines.append("═══════════════════════════════════════")

		if let status = log.statusCode {
			lines.append("Status: \(status) \(HTTPURLResponse.localizedString(forStatusCode: status))")
		}
		if let duration = log.metrics.duration {
			lines.append(String(format: "Duration: %.0fms", duration * 1000))
		}

		if let headers = log.requestHeaders, !headers.isEmpty {
			lines.append("")
			lines.append("── Request Headers ──")
			for key in headers.keys.sorted() {
				lines.append("  \(key): \(headers[key] ?? "")")
			}
		}

		if let body = log.requestBody, !body.isEmpty {
			lines.append("")
			lines.append("── Request Body ──")
			lines.append(Self.prettyString(from: body))
		}

		if let headers = log.responseHeaders, !headers.isEmpty {
			lines.append("")
			lines.append("── Response Headers ──")
			for key in headers.keys.sorted() {
				lines.append("  \(key): \(headers[key] ?? "")")
			}
		}

		if let body = log.responseBody, !body.isEmpty {
			lines.append("")
			lines.append("── Response Body ──")
			lines.append(Self.prettyString(from: body))
		}

		if let error = log.error {
			lines.append("")
			lines.append("── Error ──")
			lines.append("  \(error)")
		}

		lines.append("═══════════════════════════════════════")
		print(lines.joined(separator: "\n"))
	}

	private static func prettyString(from data: Data) -> String {
		if let obj = try? JSONSerialization.jsonObject(with: data),
		   let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
		   let str = String(data: pretty, encoding: .utf8) {
			return str
		}
		return String(data: data, encoding: .utf8) ?? "\(data.count) bytes (binary)"
	}

	
	private var overviewSection: some View {
		Section("Overview") {
			row("Method", log.method)
			if let tags = log.tags {
				HStack {
					Text("Status")
						.foregroundStyle(.secondary)
					Spacer()
					TagsView(tags)
				}
			}
			
			row("URL", log.url.absoluteString)
			if let status = log.statusCode {
				HStack {
					Text("Status")
						.foregroundStyle(.secondary)
					Spacer()
					Text("\(status) \(HTTPURLResponse.localizedString(forStatusCode: status))")
						.foregroundStyle(statusColor(status))
						.fontWeight(.semibold)
				}
			}
			row("Timestamp", log.timestamp.chronicle_formatted)
		}
	}
	
	private var requestSection: some View {
		Section("Request") {
			if let headers = log.requestHeaders, !headers.isEmpty {
				headersView("Headers", headers)
			}
			if let body = log.requestBody, !body.isEmpty {
				DataBodyView(title: "Body", data: body)
			} else if let size = log.requestBodySize {
				row("Body Size", ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
			}
		}
	}
	
	private var responseSection: some View {
		Section("Response") {
			if let headers = log.responseHeaders, !headers.isEmpty {
				headersView("Headers", headers)
			}
			if let body = log.responseBody, !body.isEmpty {
				DataBodyView(title: "Body", data: body)
			} else if let size = log.responseBodySize {
				row("Body Size", ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
			}
		}
	}
	
	private var metricsSection: some View {
		Section("Metrics") {
			if let duration = log.metrics.duration {
				row("Duration", String(format: "%.0fms", duration * 1000))
			}
			row("Bytes Sent", ByteCountFormatter.string(fromByteCount: log.metrics.bytesSent, countStyle: .file))
			row("Bytes Received", ByteCountFormatter.string(fromByteCount: log.metrics.bytesReceived, countStyle: .file))
		}
	}
	
	private var errorSection: some View {
		Section("Error") {
			if let error = log.error {
				Text(error)
					.foregroundStyle(.red)
			}
			if let errorID = log.linkedErrorID {
				row("Linked Error ID", errorID.uuidString)
			}
		}
	}
	
	@ViewBuilder
	private var sourceSection: some View {
		if log.sourceFile != nil || log.sourceFunction != nil {
			Section("Source") {
				if let file = log.sourceFile, let line = log.sourceLine {
					monoRow("Location", "\(file):\(line)")
				}
				if let function = log.sourceFunction {
					monoRow("Function", function)
				}
			}
		}
	}
}
