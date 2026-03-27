import SwiftUI

/// A SwiftUI screen that displays Chronicle entry history with filtering.
@available(iOS 17, macOS 14, *)
public struct ChronicleScreen: View {
    @State private var model = ChronicleViewerModel()
    @State private var showClearConfirmation = false
    @State private var selectedTab = 0

    public init() {}

    public var body: some View {
        Group {
            if #available(iOS 26, macOS 26, *) {
                modernTabs
            } else {
                legacyTabs
            }
        }
        .onChange(of: selectedTab) {
            model.showCurrentRunOnly = selectedTab == 0
        }
    }

    @available(iOS 26, macOS 26, *)
    private var modernTabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Current Run", systemImage: "clock", value: 0) {
                ChronicleTabContent(model: model, showClearConfirmation: $showClearConfirmation, currentRunOnly: true)
            }
            Tab("History", systemImage: "calendar", value: 1) {
                ChronicleTabContent(model: model, showClearConfirmation: $showClearConfirmation, currentRunOnly: false)
            }
            Tab(value: 2, role: .search) {
                ChronicleTabContent(model: model, showClearConfirmation: $showClearConfirmation, currentRunOnly: model.showCurrentRunOnly)
                    .searchable(text: $model.searchText, prompt: "Filter entries")
            }
        }
    }

    private var legacyTabs: some View {
        TabView(selection: $selectedTab) {
            ChronicleTabContent(model: model, showClearConfirmation: $showClearConfirmation, currentRunOnly: true)
                .searchable(text: $model.searchText, prompt: "Filter entries")
                .tag(0)
                .tabItem { Label("Current Run", systemImage: "play.circle") }

            ChronicleTabContent(model: model, showClearConfirmation: $showClearConfirmation, currentRunOnly: false)
                .searchable(text: $model.searchText, prompt: "Filter entries")
                .tag(1)
                .tabItem { Label("All History", systemImage: "clock") }
        }
    }
}
