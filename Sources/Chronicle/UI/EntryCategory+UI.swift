import SwiftUI

extension EntryCategory {
    var displayName: String {
        switch self {
        case .event: "Events"
        case .network: "Network"
        case .flow: "Flow"
        case .error: "Errors"
        }
    }

    var systemImage: String {
        switch self {
        case .event: "bolt.fill"
        case .network: "network"
        case .flow: "arrow.triangle.swap"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .event: .blue
        case .network: .green
        case .flow: .purple
        case .error: .red
        }
    }
}
