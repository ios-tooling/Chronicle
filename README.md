# Chronicle

Event, network, flow, and error tracking framework for iOS 17+ / macOS 14+. Persists via SwiftData with a built-in SwiftUI viewer.

## Setup

```swift
// Package.swift
.package(url: "https://github.com/ios-tooling/Chronicle", from: "1.0.0")
```

```swift
// App launch
try Chronicle.shared.configure()

// Or with custom config
let config = ChronicleConfiguration(
    isEnabled: true,
    modelContainer: myContainer,
    exportDestinations: [ConsoleExporter()]
)
try Chronicle.shared.configure(config)

// In-memory for testing
try Chronicle.shared.configureInMemory()
```

## Logging

All logging methods capture source location (`#file`, `#function`, `#line`) automatically.

```swift
// Events
Chronicle.track("button_tapped", metadata: ["id": "checkout"])

// Network — auto-creates linked ErrorLog when error is non-nil
Chronicle.network(request: urlRequest, response: httpResponse, data: data, error: error)

// Screen flow
Chronicle.flow("HomeScreen", transition: .push)

// Errors
Chronicle.error(someError, severity: .critical, context: ["screen": "checkout"])
```

### Automatic network interception

```swift
let config = Chronicle.shared.network.interceptingSessionConfiguration()
let session = URLSession(configuration: config)
// All requests through this session are logged automatically
```

## Querying

```swift
let all = Chronicle.shared.allEntries()

let query = StorageQuery(
    categories: [.event, .error],
    since: Date().addingTimeInterval(-3600),
    limit: 50,
    nameContains: "checkout"
)
let filtered = Chronicle.shared.entries(matching: query)

// By tracker
Chronicle.shared.errors.errors(withSeverity: .critical)
Chronicle.shared.network.recentLogs(limit: 20)
Chronicle.shared.flow.breadcrumbs(limit: 50)
Chronicle.shared.flow.getCurrentScreen()
```

## UI

```swift
// Full viewer screen
ChronicleScreen()

// Button that presents ChronicleScreen in a sheet
ChronicleButton()
```

The viewer supports filtering by entry category, current run vs. all history, and text search.

## Export

```swift
let report = try Chronicle.shared.generateReport(
    from: startDate,
    to: endDate,
    title: "Session Report"
)
```

## Architecture

### Entry types

All conform to `ChronicleEntry` (requires `id: UUID`, `timestamp: Date`, `category: EntryCategory`).

| Type | Category | Key fields |
|------|----------|------------|
| `Event` | `.event` | `name`, `metadata: EventMetadata?` |
| `NetworkLog` | `.network` | `url`, `method`, `statusCode`, `metrics: NetworkMetrics`, `linkedErrorID: UUID?` |
| `FlowEvent` | `.flow` | `from: FlowStep?`, `to: FlowStep`, `transitionType: TransitionType` |
| `ErrorLog` | `.error` | `domain`, `code`, `message`, `errorType`, `severity: ErrorSeverity`, `linkedNetworkLogID: UUID?` |

All entry types include `sourceFile: String?`, `sourceFunction: String?`, `sourceLine: Int?`.

### Network-error linking

When `NetworkLogger.log(request:..., error:...)` receives a non-nil error, it creates both a `NetworkLog` and a linked `ErrorLog` with cross-referenced UUIDs (`linkedErrorID` / `linkedNetworkLogID`).

### Storage

SwiftData-backed with four `@Model` types (`PersistedEvent`, `PersistedNetworkLog`, `PersistedFlowEvent`, `PersistedErrorLog`). Complex fields (metadata, headers) are stored as JSON `Data`. Source location fields are direct columns.

### File structure

```
Sources/Chronicle/
├── Chronicle.swift              # Singleton coordinator
├── Chronicle+Static.swift       # Static convenience API
├── Core/
│   ├── ChronicleEntry.swift     # Protocol + EntryCategory
│   ├── ChronicleConfiguration.swift
│   └── AnyCodableValue.swift
├── Events/
│   ├── Event.swift
│   ├── EventMetadata.swift
│   └── EventTracker.swift
├── Network/
│   ├── NetworkLog.swift
│   ├── NetworkMetrics.swift
│   ├── NetworkLogger.swift
│   └── URLSessionInterceptor.swift
├── Flow/
│   ├── FlowEvent.swift
│   ├── FlowStep.swift           # TransitionType, LifecycleEvent, FlowStep
│   └── FlowTracker.swift
├── Errors/
│   ├── ErrorLog.swift           # ErrorSeverity + ErrorLog
│   └── ErrorTracker.swift
├── Storage/
│   ├── SwiftDataStorage.swift
│   ├── SwiftDataModels.swift
│   └── StorageQuery.swift
├── Export/
│   ├── ExportDestination.swift
│   ├── ConsoleExporter.swift
│   └── MarkdownExporter.swift
└── UI/
    ├── ChronicleScreen.swift
    ├── ChronicleViewerModel.swift
    ├── ChronicleFilterBar.swift
    ├── ChronicleButton.swift
    ├── EntryCategory+UI.swift
    ├── EntryRow.swift
    ├── EventRow.swift
    ├── NetworkLogRow.swift
    ├── FlowEventRow.swift
    └── ErrorLogRow.swift
```

### Thread safety

`Chronicle` and `FlowTracker` use `NSLock`. All tracker classes are `Sendable`. Static convenience methods are `nonisolated`.

### Key protocols

- **`ChronicleEntry`** — `Codable & Sendable`, requires `id`, `timestamp`, `category`
- **`ExportDestination`** — `Sendable`, requires `func export(_ entries:) throws -> Data?`
