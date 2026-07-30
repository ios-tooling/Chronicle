# Chronicle Code Audit

Generated 2026-07-09. Scope: ~79 Swift files, ~6,500 Swift LOC, 0 Metal files across the Chronicle Swift package and the ChronicleViewer macOS app. Excluded directories: `.git/`, `.build/`, `Dead/`, `Pods/`, and third-party package checkouts.

Findings cite `path/to/file.swift:LINE` so each item can be opened directly. No production code was changed.

Build baseline:

- `swift package clean && swift build`: passed with no warnings.
- `swift test`: passed 44 tests in 7 suites.
- `xcodebuild -project ChronicleViewer/ChronicleViewer.xcodeproj -scheme ChronicleViewer -configuration Debug clean build`: passed with one Swift warning in `DatabaseWatcher.swift`.

---

## 1. Executive summary

Top items to address, in priority order:

1. **[High] Disabled logging still records entries** — §5.1 — `Sources/Chronicle/Core/ChronicleConfiguration.swift:7-13`, `Sources/Chronicle/Chronicle.swift:100-130`. `isEnabled: false` is accepted but never gates storage, so consumers can believe logging is disabled while data is still persisted.
2. **[High] SwiftData failures are silently converted to success** — §5.2 — `Sources/Chronicle/Storage/SwiftDataStorage.swift:68-87`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:172-205`. Save, fetch, and delete failures are swallowed, hiding dropped logs and failed clears.
3. **[High] Read-only Viewer exposes a destructive Clear action** — §5.3 — `ChronicleViewer/ChronicleViewer/ContentView+Database.swift:95-103`, `Sources/Chronicle/UI/ChronicleTabContent.swift:121-170`. External databases are opened read-only, but the shared UI still offers Clear and reports no failure.
4. **[High] Public `ChronicleScreen` can crash before configuration** — §5.4 — `Sources/Chronicle/UI/ChronicleScreen.swift:5-7`, `Sources/Chronicle/UI/ChronicleViewerModel.swift:24-28`. A public view constructor can hit `fatalError` in release apps.
5. **[High] Static network logging can skip linked `ErrorLog` creation** — §5.5 — `Sources/Chronicle/Static Methods/Chronicle+Network.swift:26-66`, `Sources/Chronicle/Network/NetworkLogger.swift:23-28`. Passing metrics changes the path and can lose automatic error linkage.
6. **[High] CloudKit zone logs are omitted from CloudKit APIs and category queries** — §5.6 — `Sources/Chronicle/Storage/SwiftDataStorage.swift:144-146`, `Sources/Chronicle/CloudKit/CloudKitLogger.swift:210-221`. Zone-created/deleted logs can disappear from filtered queries.
7. **[High] CloudKit record cache is not cleared with logs** — §5.7 — `Sources/Chronicle/CloudKit/CKRecordCache.swift:19-25`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:172-205`. Clearing history can leave archived CKRecord payloads on disk.
8. **[High] Sensitive request/error data is persisted without redaction controls** — §6.1 — `Sources/Chronicle/Network/NetworkLogger.swift:30-38`, `Sources/Chronicle/Errors/ErrorTracker.swift:96-139`. Headers, bodies, error userInfo, URLs, and call stacks can be retained in the Chronicle database.
9. **[High] ChronicleViewer has a real MainActor build warning** — §3.1 — `ChronicleViewer/ChronicleViewer/DatabaseWatcher.swift:10-43`. The clean Viewer build warns on a main-actor method called from a nonisolated timer closure.
10. **[High] CloudKit cache state is marked Sendable without full synchronization** — §3.2 — `Sources/Chronicle/CloudKit/CloudKitLogger.swift:7-31`, `Sources/Chronicle/CloudKit/CKRecordCache.swift:28-84`. Concurrent cache resizing, logging, and clearing can race.

---

## 2. Quick wins (≤30 min each)

- **Fix the Viewer timer warning** — §3.1 — `ChronicleViewer/ChronicleViewer/DatabaseWatcher.swift:37-43`. Add an explicit main-actor hop or replace the timer with an observation-native polling mechanism.
- **Hide Clear for read-only databases** — §5.3 — `Sources/Chronicle/UI/ChronicleTabContent.swift:121-170`. A simple configuration check prevents a destructive control that cannot succeed in ChronicleViewer.
- **Remove or gate the database path print** — §6.3 — `Sources/Chronicle/Storage/SwiftDataStorage.swift:27-34`. This logs local container paths in release-capable code.
- **Fix the duplicated “Status” label for network tags** — §8.3 — `Sources/Chronicle/UI/NetworkLogDetailScreen.swift:94-116`. The tags row should be labeled “Tags.”
- **Update README setup snippets** — §4.2 — `README.md:13-25`, `README.md:32-49`, `README.md:56-93`. Current docs use stale `Chronicle.shared`, `metadata:`, and synchronous calls.
- **Align Package.swift platform floor with SwiftData** — §4.1 — `Package.swift:7-10`, `Sources/Chronicle/Chronicle.swift:27-28`. Raise iOS to 17 or split non-SwiftData API.
- **Fix the Viewer bundle identifier typo** — §9.6 — `ChronicleViewer/ChronicleViewer.xcodeproj/project.pbxproj:277-312`. `com.standalone..ChronicleViewer` has a doubled period.
- **Include zone categories in CloudKit category sets** — §5.6 — `Sources/Chronicle/CloudKit/CloudKitLogger.swift:210-221`. One shared category set should cover all five CloudKit categories.

---

## 3. Concurrency

### 3.1 Timer closure crosses MainActor isolation
- **Location:** `ChronicleViewer/ChronicleViewer/DatabaseWatcher.swift:10-43`
- **What:** `DatabaseWatcher` is `@MainActor`, but `Timer.scheduledTimer` calls `poll()` from a synchronous closure that the compiler treats as nonisolated.
- **Why:** This is the one real Swift warning from the clean Viewer build and will become riskier as Swift concurrency checking tightens.
- **Action:** Hop explicitly to `MainActor` inside the timer closure, or replace the timer with a SwiftUI/Observation-friendly polling mechanism.
- **Severity:** High

### 3.2 CloudKit cache state is marked Sendable without full synchronization
- **Location:** `Sources/Chronicle/CloudKit/CloudKitLogger.swift:7-31`, `Sources/Chronicle/CloudKit/CloudKitLogger.swift:63-65`, `Sources/Chronicle/CloudKit/CloudKitLogger.swift:96-98`, `Sources/Chronicle/CloudKit/CloudKitLogger.swift:204-207`, `Sources/Chronicle/CloudKit/CKRecordCache.swift:28-84`
- **What:** `CloudKitLogger` is `@unchecked Sendable` but reads and mutates `_recordCache` without synchronization, and `CKRecordCache.clearAll()` mutates `manifest` without taking the cache lock.
- **Why:** Concurrent cache-size changes, record logging, record reads, and cache clearing can race, corrupting the in-memory manifest or producing stale/deleted file references.
- **Action:** Put `_recordCache` behind a lock or actor, and make every `CKRecordCache` mutation go through the same synchronized path.
- **Severity:** High

### 3.3 Fire-and-forget writes make immediate reads order-dependent
- **Location:** `Sources/Chronicle/Storage/StorageWriter.swift:17-38`, `Sources/Chronicle/Events/EventTracker.swift:15-24`, `Sources/Chronicle/Chronicle.swift:128-145`, `Tests/ChronicleTests/ChronicleIntegrationTests.swift:34-38`
- **What:** Trackers enqueue writes through `StorageWriter.store()` and return before persistence; reads query storage directly unless callers remember to call `flush()`.
- **Why:** A caller can log an entry and immediately query/export, then miss the just-logged entry because the writer task has not drained yet.
- **Action:** Either document and enforce the fire-and-forget contract, or have read/export APIs flush pending writes before querying.
- **Severity:** High

### 3.4 Flow transitions are not atomic
- **Location:** `Sources/Chronicle/Flow/FlowTracker.swift:6-15`, `Sources/Chronicle/Flow/FlowTracker.swift:22-45`
- **What:** `trackScreen` reads `currentStep`, builds a flow event, and writes `currentStep` under separate lock acquisitions.
- **Why:** Concurrent callers can both observe the same previous screen and produce an incorrect breadcrumb chain despite `@unchecked Sendable`.
- **Action:** Hold one lock across the read/build/write transition, or make `FlowTracker` an actor.
- **Severity:** Medium

### 3.5 Storage limit setup races initial writes
- **Location:** `Sources/Chronicle/Chronicle.swift:100-124`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:62-87`
- **What:** `install` publishes trackers immediately after starting an unstructured task to set `maxEntries`.
- **Why:** Writes immediately after `configure` can run before the storage actor receives `maxEntries`, bypassing retention enforcement.
- **Action:** Pass the limit during storage construction or make configuration await setting storage policy before exposing trackers.
- **Severity:** Medium

### 3.6 Category style registry opts out of compiler isolation
- **Location:** `Sources/Chronicle/Core/EntryCategoryStyle.swift:22-49`
- **What:** `_styles` is `nonisolated(unsafe)` global mutable state guarded manually by an `NSLock`.
- **Why:** Current accessors lock correctly, but the unsafe global suppresses compiler enforcement and makes future unguarded access easy to introduce.
- **Action:** Replace the unsafe static storage with an actor-backed registry or a lock wrapper that owns protected state.
- **Severity:** Low

### 3.7 Shared DateFormatter instances are globally mutable
- **Location:** `Sources/Chronicle/UI/Date+Chronicle.swift:3-28`
- **What:** The date extension uses static `DateFormatter` instances from a nonisolated extension.
- **Why:** `DateFormatter` is mutable; if these helpers are called off the UI path, shared formatter state can race.
- **Action:** Use value-style `Date.FormatStyle`, actor-isolate the helpers, or create formatters per operation where appropriate.
- **Severity:** Low

---

## 4. API modernity

### 4.1 Package platform floor contradicts SwiftData availability
- **Location:** `Package.swift:7-10`, `Sources/Chronicle/Chronicle.swift:27-28`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:10-12`, `README.md:3`
- **What:** The package advertises iOS 14 support, while the core API is SwiftData-backed and gated at iOS 17/macOS 14.
- **Why:** iOS 14-16 consumers can resolve the package but cannot use the main public API.
- **Action:** Raise the package iOS platform to `.iOS(.v17)` or split any iOS 14-compatible code into a separate layer.
- **Severity:** Medium

### 4.2 Public docs and source comments document stale APIs
- **Location:** `README.md:13-25`, `README.md:32-49`, `README.md:56-93`, `README.md:102-117`, `Sources/Chronicle/Chronicle.swift:7-25`
- **What:** The README and top-level usage comments reference `Chronicle.shared`, `metadata:`, synchronous query/report calls, `interceptingSessionConfiguration()`, and old storage file names.
- **Why:** Consumers following the docs will hit compile errors or call APIs with the wrong async model.
- **Action:** Update examples to current `Chronicle.instance`, `context:`, and `await` usage; remove or restore the documented network interception API.
- **Severity:** Medium

### 4.3 Viewer target uses Swift 5 language mode with modern concurrency flags
- **Location:** `ChronicleViewer/ChronicleViewer.xcodeproj/project.pbxproj:282-286`, `ChronicleViewer/ChronicleViewer.xcodeproj/project.pbxproj:315-319`
- **What:** The app target enables default main-actor isolation and approachable concurrency while still setting `SWIFT_VERSION = 5.0`.
- **Why:** Swift 5 mode can leave concurrency issues as warnings that Swift 6 mode would force you to resolve deliberately.
- **Action:** Move the Viewer target to Swift 6 language mode and resolve the resulting diagnostics.
- **Severity:** Medium

### 4.4 Viewer still uses Combine observation despite macOS 26 target
- **Location:** `ChronicleViewer/ChronicleViewer/DatabaseWatcher.swift:1-13`, `ChronicleViewer/ChronicleViewer/LiveChronicleView.swift:7-24`
- **What:** `DatabaseWatcher` uses `ObservableObject` and `@Published`, while the package already uses `@Observable` for `ChronicleViewerModel`.
- **Why:** The macOS 26.4 Viewer can use Observation directly, avoiding mixed observation semantics around main-actor UI state.
- **Action:** Convert `DatabaseWatcher` to `@Observable @MainActor` and store/pass it with SwiftUI Observation primitives.
- **Severity:** Low

---

## 5. Bugs / logic errors

### 5.1 Disabled logging still records entries
- **Location:** `Sources/Chronicle/Core/ChronicleConfiguration.swift:7-13`, `Sources/Chronicle/Chronicle.swift:100-130`
- **What:** `isEnabled` is stored in configuration but never checked by `configure`, `install`, `store`, or any tracker path.
- **Why:** Apps can set `isEnabled: false` and still persist logs, including potentially sensitive request and error data.
- **Action:** Gate writer/tracker storage on `configuration.isEnabled`, or install no-op trackers/storage when disabled.
- **Severity:** High

### 5.2 SwiftData failures are silently converted to success
- **Location:** `Sources/Chronicle/Storage/SwiftDataStorage.swift:68-87`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:89-123`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:172-205`, `Sources/Chronicle/Storage/SwiftDataStorage+Fetch.swift:8-45`
- **What:** Stores use `try? save()`, fetches fall back to empty arrays/counts, and clear methods use empty `catch` blocks.
- **Why:** Disk, migration, uniqueness, read-only, or corruption errors can drop logs, show empty history, or leave pending context changes without feedback.
- **Action:** Return or log structured errors, rollback failed contexts, and avoid treating failed fetches as empty successful results.
- **Severity:** High

### 5.3 Read-only Viewer exposes a destructive Clear action
- **Location:** `ChronicleViewer/ChronicleViewer/ContentView+Database.swift:95-103`, `Sources/Chronicle/UI/ChronicleTabContent.swift:121-129`, `Sources/Chronicle/UI/ChronicleTabContent.swift:163-170`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:172-205`
- **What:** External databases are opened with `allowsSave: false`, but the shared UI always shows Clear and calls async delete methods.
- **Why:** The Viewer can present a destructive confirmation that silently fails, because delete/save errors are swallowed.
- **Action:** Hide or disable Clear for read-only configurations, and make clear operations report errors.
- **Severity:** High

### 5.4 Public `ChronicleScreen` can crash before configuration
- **Location:** `Sources/Chronicle/UI/ChronicleScreen.swift:5-7`, `Sources/Chronicle/UI/ChronicleViewerModel.swift:24-28`
- **What:** `ChronicleScreen` initializes `ChronicleViewerModel()`, whose convenience initializer calls `fatalError` when Chronicle is not configured.
- **Why:** Rendering a public UI component before setup crashes release apps instead of showing a recoverable configuration state.
- **Action:** Replace the fatal precondition with a failable/loading state, or require a `ModelContainer` in the public initializer.
- **Severity:** High

### 5.5 Static network logging can skip linked `ErrorLog` creation
- **Location:** `Sources/Chronicle/Static Methods/Chronicle+Network.swift:26-66`, `Sources/Chronicle/Network/NetworkLogger.swift:23-28`
- **What:** The static request API directly constructs a `NetworkLog` whenever `metrics` or `linkedErrorID` is present, bypassing the logger path that creates a linked `ErrorLog`.
- **Why:** Logging the same failed request through the same public API can lose error linkage solely because metrics were supplied.
- **Action:** Move metrics/linked-error handling into `NetworkLogger.log(request:...)` so all request overloads share the same linking behavior.
- **Severity:** High

### 5.6 CloudKit zone logs are omitted from CloudKit APIs and category queries
- **Location:** `Sources/Chronicle/CloudKit/CloudKitLog.swift:17-24`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:144-146`, `Sources/Chronicle/CloudKit/CloudKitLogger.swift:210-221`
- **What:** Zone operations map to `.cloudKitZoneCreated` and `.cloudKitZoneDeleted`, but storage fetches and `CloudKitLogger.allLogs/recentLogs` only include upload/download/delete categories.
- **Why:** Stored zone events disappear from category-specific queries and CloudKit logger convenience APIs.
- **Action:** Define one authoritative CloudKit category set that includes all five CloudKit categories and use it in storage and logger APIs.
- **Severity:** High

### 5.7 CloudKit record cache is not cleared with logs
- **Location:** `Sources/Chronicle/CloudKit/CloudKitLogger.swift:63-65`, `Sources/Chronicle/CloudKit/CloudKitLogger.swift:96-97`, `Sources/Chronicle/CloudKit/CloudKitLogger.swift:124-125`, `Sources/Chronicle/CloudKit/CloudKitLogger.swift:204-207`, `Sources/Chronicle/CloudKit/CKRecordCache.swift:19-25`, `Sources/Chronicle/CloudKit/CKRecordCache.swift:77-83`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:172-205`
- **What:** Cached `CKRecord` archives are written under Caches independently of SwiftData, while `clear()` only deletes SwiftData models.
- **Why:** Clear All can leave CloudKit record details on disk after their log entries are removed.
- **Action:** Tie CKRecord cache cleanup to Chronicle clear/delete operations, and expose explicit cache-clearing behavior in the UI where appropriate.
- **Severity:** High

### 5.8 Failed second database open can leave stale Viewer state active
- **Location:** `ChronicleViewer/ChronicleViewer/ContentView+Database.swift:28-31`, `ChronicleViewer/ChronicleViewer/ContentView+Database.swift:88-108`, `ChronicleViewer/ChronicleViewer/ContentView.swift:15-20`, `ChronicleViewer/ChronicleViewer/ContentView.swift:52-56`
- **What:** Selecting a new database stops the old security scope before opening the new one; if open fails, old `model`/`watcher`/`selectedURL` can remain.
- **Why:** Users can keep seeing the previous database while access to it was stopped, and `selectedURL!` can crash if state becomes inconsistent.
- **Action:** Build the new container first, then atomically swap state on success; on failure, either keep the old database fully active or explicitly clear all viewer state.
- **Severity:** High

### 5.9 Error cancellation filtering is overload-specific
- **Location:** `Sources/Chronicle/Static Methods/Chronicle+Errors.swift:7-42`, `Sources/Chronicle/Static Methods/Chronicle+Errors.swift:45-49`
- **What:** The `context: String?` overload suppresses cancellation errors, but the primary `context: EventMetadata?` overload logs them.
- **Why:** Callers get different behavior depending on overload selection, making cancellation noise hard to reason about.
- **Action:** Centralize cancellation filtering in `ErrorTracker` or a shared static helper before both overloads log.
- **Severity:** Medium

### 5.10 Query limit is applied before text filtering
- **Location:** `Sources/Chronicle/Storage/SwiftDataStorage.swift:127-162`, `Sources/Chronicle/Storage/SwiftDataStorage+Fetch.swift:8-45`
- **What:** Storage fetches and converts rows, sorts in memory, applies `limit`, then applies `nameContains`.
- **Why:** Limited text queries can miss matching older entries that were outside the pre-filtered suffix, and large histories pay full fetch/conversion cost even for small limits.
- **Action:** Push supported predicates and fetch limits into `FetchDescriptor`, and apply text filtering before final limiting when in-memory filtering is required.
- **Severity:** Medium

### 5.11 Persistence round-trips drop or rewrite entry data
- **Location:** `Sources/Chronicle/Storage/PersistedGenericEntry.swift:20-50`, `Sources/Chronicle/Storage/PersistedNetworkLog.swift:90-105`, `Sources/Chronicle/Storage/PersistedCloudKitLog.swift:69-77`
- **What:** Generic entries do not persist `referenceURL`/`referenceID`, and invalid persisted values silently become `https://unknown` or `.download`.
- **Why:** External or older databases can display misleading entries, and custom entry links disappear after storage.
- **Action:** Persist reference fields for generic entries and preserve unknown/corrupt raw values instead of defaulting them silently.
- **Severity:** Medium

---

## 6. Security

### 6.1 Sensitive request and error data is persisted without redaction controls
- **Location:** `Sources/Chronicle/Network/NetworkLogger.swift:30-38`, `Sources/Chronicle/Static Methods/Chronicle+Network.swift:28-38`, `Sources/Chronicle/Static Methods/Chronicle+Network.swift:94-103`, `Sources/Chronicle/Errors/ErrorTracker.swift:96-139`, `Sources/Chronicle/Storage/PersistedNetworkLog.swift:14-20`
- **What:** Request headers, request bodies, response bodies, error `userInfo`, URLs, source paths, and optional call stacks are stored directly.
- **Why:** Authorization headers, cookies, tokens, PII, and local paths can be retained in the Chronicle database and opened later in the Viewer.
- **Action:** Add default redaction for sensitive headers/keys, make body capture opt-in or size-limited, and support allowlist-based error metadata capture.
- **Severity:** High

### 6.2 Console dump affordances can print payloads and errors
- **Location:** `Sources/Chronicle/UI/DataBodyScreen.swift:32-49`, `Sources/Chronicle/UI/ErrorLogDetailScreen.swift:20-65`, `Sources/Chronicle/UI/NetworkLogDetailScreen.swift:23-81`
- **What:** UI detail screens can dump request/response bodies, errors, context, headers, and call stacks with `print()`.
- **Why:** These dumps can expose sensitive payloads in console logs beyond the database itself.
- **Action:** Gate dump actions behind `#if DEBUG` or an explicit debug configuration, and redact sensitive fields before output.
- **Severity:** Medium

### 6.3 Database and watcher paths are printed in release-capable code
- **Location:** `Sources/Chronicle/Storage/SwiftDataStorage.swift:27-34`, `ChronicleViewer/ChronicleViewer/DatabaseWatcher.swift:37-48`
- **What:** Storage setup prints the database path, and the Viewer watcher prints filesystem-change messages.
- **Why:** App container paths and local database locations are not usually sensitive alone, but they are unnecessary release console output and can aid data discovery.
- **Action:** Replace with `os.Logger` at debug level and compile/debug-gate path logging.
- **Severity:** Low

---

## 7. Performance

### 7.1 Main viewer recomputes full history and export text in body paths
- **Location:** `Sources/Chronicle/UI/ChronicleTabContent.swift:67-94`, `Sources/Chronicle/UI/ChronicleTabContent.swift:97-142`, `Sources/Chronicle/UI/ChronicleSearchTab.swift:34-59`, `Sources/Chronicle/UI/ChronicleSearchTab.swift:62-81`
- **What:** SwiftUI body paths repeatedly map six `@Query` arrays to entries, sort/filter/count them, and build Markdown for `ShareLink`.
- **Why:** Large databases can stall scrolling, filtering, and initial rendering before the user even taps Export.
- **Action:** Move derived entry lists into cached model state or paged fetches, and generate exports on explicit share/export action.
- **Severity:** Medium

### 7.2 Data body screens render whole payloads synchronously
- **Location:** `Sources/Chronicle/UI/DataBodyScreen.swift:10-19`, `Sources/Chronicle/UI/DataBodyScreen.swift:51-76`, `Sources/Chronicle/UI/NetworkLogDetailScreen.swift:121-143`
- **What:** JSON parsing, UTF-8 conversion, binary hex mapping, line splitting, and body navigation are performed directly from full `Data` values.
- **Why:** Large request/response bodies can allocate huge strings and freeze the UI.
- **Action:** Cap previews, parse off-main on demand, and page or stream large payload views.
- **Severity:** Medium

### 7.3 Live refresh churns ModelContainers and hides reload failures
- **Location:** `ChronicleViewer/ChronicleViewer/DatabaseWatcher.swift:37-48`, `ChronicleViewer/ChronicleViewer/LiveChronicleView.swift:23-44`
- **What:** Every detected modification starts a main-actor refresh that creates a new `ModelContainer`, reconfigures the singleton, and ignores thrown errors.
- **Why:** Active databases can cause repeated container churn and stale UI when a reload fails.
- **Action:** Debounce and cancel refresh tasks, surface reload errors, and consider a Viewer-specific read model instead of global singleton reconfiguration.
- **Severity:** Medium

### 7.4 Per-entry storage does immediate save and retention work
- **Location:** `Sources/Chronicle/Storage/SwiftDataStorage.swift:68-87`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:89-123`
- **What:** Each stored entry inserts, optionally runs up to six count queries and six oldest-entry fetches, then saves immediately.
- **Why:** High-volume logging amplifies SwiftData I/O and actor work on every event.
- **Action:** Batch writes, save periodically or on flush, and enforce retention through cheaper indexed or scheduled cleanup.
- **Severity:** Medium

---

## 8. SwiftUI / UI

### 8.1 `ChronicleTabContent` is doing too much view, query, filtering, clear, and export work
- **Location:** `Sources/Chronicle/UI/ChronicleTabContent.swift:31-208`
- **What:** One private view owns six queries, derived arrays, filtering, filter bar controls, export generation, clear confirmation, empty state, and list presentation.
- **Why:** The view is hard to reason about and repeats logic already present in `ChronicleSearchTab`, increasing drift risk.
- **Action:** Extract query aggregation, filter UI, export action, and clear confirmation into smaller dedicated views/models.
- **Severity:** Medium

### 8.2 Search and tab views duplicate query and filter logic
- **Location:** `Sources/Chronicle/UI/ChronicleTabContent.swift:39-95`, `Sources/Chronicle/UI/ChronicleSearchTab.swift:27-60`
- **What:** Current/history and search views both declare six `@Query` properties, build `allEntries`, and apply category/tag/search filters.
- **Why:** Search, export, empty-state, and category behavior can drift between tabs.
- **Action:** Extract a shared query-owning content view or an entry aggregation model used by both surfaces.
- **Severity:** Medium

### 8.3 Network detail tags row is mislabeled as Status
- **Location:** `Sources/Chronicle/UI/NetworkLogDetailScreen.swift:94-116`
- **What:** When `log.tags` exists, the row label says “Status” while displaying tags.
- **Why:** The detail screen becomes misleading and duplicates the actual status label below it.
- **Action:** Change the label to “Tags” or render tags in a dedicated tags section.
- **Severity:** Low

### 8.4 Icon-only toolbar buttons rely on accessibility labels instead of visible text
- **Location:** `Sources/Chronicle/UI/ChronicleTabContent.swift:111-138`, `ChronicleViewer/ChronicleViewer/ContentView.swift:76-84`
- **What:** Several controls are icon-only buttons, with labels provided through view modifiers or help text rather than text-bearing button initializers.
- **Why:** This is workable, but less robust for VoiceOver and Voice Control than buttons with stable textual labels.
- **Action:** Prefer `Button("Clear entries", systemImage: ...)` or `Label`-based content with hidden visual text where needed.
- **Severity:** Low

### 8.5 `ChronicleScreen` tab selection uses integer tags instead of a typed enum
- **Location:** `Sources/Chronicle/UI/ChronicleScreen.swift:6-8`, `Sources/Chronicle/UI/ChronicleScreen.swift:25-52`
- **What:** `TabView(selection:)` is backed by raw integers.
- **Why:** Integer tags make tab state harder to read and easier to misuse as the tab set grows.
- **Action:** Replace the integer selection with a small `enum` for current run, history, and search.
- **Severity:** Low

---

## 9. Dead code / duplication / refactor

### 9.1 Commented-out export pipeline leaves config fields inert
- **Location:** `Sources/Chronicle/Core/ChronicleConfiguration.swift:7-24`, `Sources/Chronicle/Chronicle.swift:163-170`
- **What:** `isEnabled` and `exportDestinations` are public configuration fields, but the only export loop is commented out and runtime code never checks the fields.
- **Why:** Consumers can configure options that have no effect, and the commented implementation is stale against current async APIs.
- **Action:** Either implement enabled/export behavior through the writer/storage pipeline or remove the fields and commented block until supported.
- **Severity:** Medium

### 9.2 SwiftData model registry is repeated across storage and UI
- **Location:** `Sources/Chronicle/Storage/SwiftDataStorage.swift:15-23`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:68-87`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:90-123`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:127-163`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:172-205`, `Sources/Chronicle/UI/ChronicleTabContent.swift:39-76`, `Sources/Chronicle/UI/ChronicleSearchTab.swift:27-42`
- **What:** The six persisted model types are manually listed in schema setup, storing, retention, querying, clearing, and viewer queries.
- **Why:** Adding or changing an entry type requires synchronized edits across many sites and increases omission risk.
- **Action:** Centralize persisted-entry metadata behind a registry/adapter protocol used by storage and UI query composition.
- **Severity:** Medium

### 9.3 Persisted conversions duplicate shared-field handling
- **Location:** `Sources/Chronicle/Storage/PersistedGenericEntry.swift:32-50`, `Sources/Chronicle/Storage/PersistedNetworkLog.swift:90-164`, `Sources/Chronicle/Storage/PersistedCloudKitLog.swift:69-117`
- **What:** Persisted models repeat JSON, tags, reference URL, and source-location conversion patterns.
- **Why:** Encoding failures, default values, and shared-field additions can become inconsistent across entry types.
- **Action:** Extract helpers or an embedded persisted-common-fields value for context/tags/reference/source conversion.
- **Severity:** Medium

### 9.4 Date predicates are duplicated per persisted model
- **Location:** `Sources/Chronicle/Storage/SwiftDataStorage+Fetch.swift:56-116`
- **What:** Six `applyDatePredicate` overloads repeat the same since/until predicate logic.
- **Why:** Date filtering changes require six edits and can drift silently.
- **Action:** Extract a shared date-query builder pattern or constrain persisted models through a timestamp-bearing abstraction where SwiftData allows it.
- **Severity:** Low

### 9.5 Exporters duplicate entry formatting switches
- **Location:** `Sources/Chronicle/Export/ConsoleExporter.swift:19-65`, `Sources/Chronicle/Export/MarkdownExporter.swift:60-106`
- **What:** Console and Markdown exporters both switch over entry types and separately format status, duration, size, error, flow, and CloudKit text.
- **Why:** New entry types or formatting fixes require duplicated exporter work.
- **Action:** Add a shared entry formatter/visitor that produces normalized presentation data, then let each exporter render syntax.
- **Severity:** Low

### 9.6 Hardcoded identifiers and sentinels are scattered
- **Location:** `Sources/Chronicle/Storage/SwiftDataStorage.swift:28-32`, `Sources/Chronicle/Storage/SwiftDataStorage.swift:56-58`, `Sources/Chronicle/CloudKit/CKRecordCache.swift:19-25`, `Sources/Chronicle/Static Methods/Chronicle+CloudKit.swift:12-107`, `Sources/Chronicle/Network/NetworkLogger.swift:30-45`, `Sources/Chronicle/Storage/PersistedNetworkLog.swift:101-105`, `ChronicleViewer/ChronicleViewer.xcodeproj/project.pbxproj:277-312`
- **What:** `history.db`, cache directory names, `_defaultOwner`, `https://unknown`, and `com.standalone..ChronicleViewer` are hardcoded in multiple places.
- **Why:** Identifier changes and sentinel semantics can drift; the Viewer bundle identifier also contains a doubled period.
- **Action:** Centralize database/cache names, bundle identifiers, CloudKit owner constants, and unknown-URL handling in named constants or typed sentinels.
- **Severity:** Medium

---

## 10. Cross-cutting recommendations

1. **Define a single entry-type registry.** Storage, UI, export, filtering, and clearing all manually enumerate entry types today; a registry/adapter layer would reduce omission bugs like the CloudKit zone category issue in §5.6.
2. **Make storage errors observable.** The library currently optimizes for nonthrowing logging, but silent save/fetch/delete failure affects the Viewer, clear actions, retention, and exports; capture errors through `os.Logger`, delegate callbacks, or a diagnostics stream.
3. **Separate recorder and viewer concerns.** The embedded app-facing `ChronicleScreen` and the external read-only `ChronicleViewer` share UI and singleton state, which creates issues around destructive controls, read-only stores, and container refresh churn.
4. **Add privacy policy knobs at the logging boundary.** Redaction, body capture, and userInfo capture should be decided before persistence, not only during export/viewing.
5. **Tighten public API contracts.** Either support `isEnabled`, `exportDestinations`, and documented interception APIs, or remove/stub them clearly so consumers do not rely on inert configuration.

---

## 11. What was NOT audited

- Algorithmic correctness of SwiftData migrations across historical database schemas was not tested with old on-disk stores.
- Third-party package internals (`TagAlong`, `CloudSeeding`, `Suite`, `swift-syntax`) were treated as black boxes.
- Xcode signing/provisioning was only scanned for obvious issues; no distribution/archive audit was performed.
- Accessibility was reviewed statically only; no VoiceOver or keyboard navigation run was performed in the app.
- Performance findings are static hot-path risks only; no Instruments profiling was run.
- Localization correctness and string catalog completeness were not assessed.
- Test coverage quality was scanned lightly; this was not a dedicated test strategy audit.

---

## 12. Verification

Spot-check pattern: open the cited file and line range. Each High finding below has exact lines that prove the claim.

- **§3.1** — open `ChronicleViewer/ChronicleViewer/DatabaseWatcher.swift`, lines `10-43`. The class is `@MainActor`; `Timer.scheduledTimer` calls `self?.poll()` from the timer closure, matching the xcodebuild warning.
- **§3.2** — open `Sources/Chronicle/CloudKit/CloudKitLogger.swift`, lines `7-31` and `63-65`; `_recordCache` is unsynchronized in an `@unchecked Sendable` class. Open `Sources/Chronicle/CloudKit/CKRecordCache.swift`, lines `77-83`; `clearAll()` mutates `manifest` without `lock.withLock`.
- **§3.3** — open `Sources/Chronicle/Storage/StorageWriter.swift`, lines `17-38`, and `Sources/Chronicle/Events/EventTracker.swift`, lines `15-24`. Writes are enqueued and tests explicitly call `flush()` before reading at `Tests/ChronicleTests/ChronicleIntegrationTests.swift:34-38`.
- **§5.1** — open `Sources/Chronicle/Core/ChronicleConfiguration.swift`, lines `7-13`, and `Sources/Chronicle/Chronicle.swift`, lines `100-130`. `isEnabled` is defined but not checked before installing trackers or storing entries.
- **§5.2** — open `Sources/Chronicle/Storage/SwiftDataStorage.swift`, lines `68-87` and `172-205`. Saves use `try?`; clear methods catch and discard all errors.
- **§5.3** — open `ChronicleViewer/ChronicleViewer/ContentView+Database.swift`, lines `95-103`, and `Sources/Chronicle/UI/ChronicleTabContent.swift`, lines `121-170`. The Viewer opens read-only, while the shared clear button still calls `Chronicle.instance.clear()`.
- **§5.4** — open `Sources/Chronicle/UI/ChronicleScreen.swift`, lines `5-7`, and `Sources/Chronicle/UI/ChronicleViewerModel.swift`, lines `24-28`. The public screen constructs a model that calls `fatalError` when unconfigured.
- **§5.5** — open `Sources/Chronicle/Static Methods/Chronicle+Network.swift`, lines `26-66`, and `Sources/Chronicle/Network/NetworkLogger.swift`, lines `23-28`. The metrics branch constructs `NetworkLog` directly instead of using the linking path.
- **§5.6** — open `Sources/Chronicle/CloudKit/CloudKitLog.swift`, lines `17-24`, `Sources/Chronicle/Storage/SwiftDataStorage.swift`, lines `144-146`, and `Sources/Chronicle/CloudKit/CloudKitLogger.swift`, lines `210-221`. Zone categories exist but are not included in the query category sets.
- **§5.7** — open `Sources/Chronicle/CloudKit/CKRecordCache.swift`, lines `19-25` and `77-83`, plus `Sources/Chronicle/Storage/SwiftDataStorage.swift`, lines `172-205`. CKRecord archives live outside SwiftData and clear methods only delete SwiftData models.
- **§5.8** — open `ChronicleViewer/ChronicleViewer/ContentView+Database.swift`, lines `28-31` and `88-108`, plus `ChronicleViewer/ChronicleViewer/ContentView.swift`, lines `52-56`. Old security scope is stopped before the new database is opened, and `selectedURL!` is force-unwrapped in the content path.
- **§6.1** — open `Sources/Chronicle/Network/NetworkLogger.swift`, lines `30-38`, `Sources/Chronicle/Errors/ErrorTracker.swift`, lines `96-139`, and `Sources/Chronicle/Storage/PersistedNetworkLog.swift`, lines `14-20`. Headers, bodies, and error metadata are captured and persisted directly.

If any finding does not reproduce when you visit the line, re-check the current branch against this audit snapshot before closing it.
