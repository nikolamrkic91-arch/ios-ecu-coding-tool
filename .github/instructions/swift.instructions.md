---
applyTo: "**/*.swift"
---

# Swift Guidelines for iOS ECU Coding Tool

## Code Style

### Naming Conventions
- Use PascalCase for types (classes, structs, enums, protocols)
- Use camelCase for functions, variables, and properties
- Use descriptive names; avoid single-letter variables except in closures
- Keep automotive acronyms uppercase (ECU, VIN, UDS, KWP, DTC, ENET)
- Use clear prefixes for protocol names (e.g., `TransportProtocol`, not just `Transport`)

### Type Choices
- Prefer `struct` over `class` unless you need reference semantics or inheritance
- Use `enum` with associated values for modeling variants (e.g., error types, states)
- Use `protocol` for abstraction and testability
- Use `actor` for thread-safe state management when dealing with concurrent access

### Property Declarations
- Use `let` by default; only use `var` when mutation is necessary
- Prefer computed properties over methods for simple calculations
- Use property wrappers (`@State`, `@Published`, `@StateObject`, `@ObservedObject`) appropriately in SwiftUI

### Function Design
- Keep functions focused and single-purpose
- Use default parameter values to reduce overloads
- Prefer throwing functions over returning optional for operations that can fail
- Use async/await for asynchronous operations
- Mark functions with appropriate access control (`private`, `fileprivate`, `internal`, `public`)

## Error Handling

### Error Types
Define specific error enums per layer:
```swift
enum TransportError: Error {
    case connectionFailed(reason: String)
    case timeout
    case invalidResponse
}

enum CodingError: Error {
    case unsupportedChassis(String)
    case backupFailed
    case preflightCheckFailed(PreflightIssue)
}
```

### Error Propagation
- Use `throws` for operations that can fail
- Don't catch and ignore errors; always handle or propagate
- Provide context in error messages
- Use `Result<Success, Failure>` for APIs that need explicit error handling

## Async/Concurrency

### Async/Await
- Use `async`/`await` for all I/O operations (network, disk, database)
- Mark functions `async` when they perform asynchronous work
- Use `Task` for bridging to SwiftUI or synchronous contexts
- Handle cancellation properly with `Task.isCancelled`

### Actors
- Use actors for mutable state that's accessed from multiple contexts
- Consider using `@MainActor` for UI-related properties and methods
- Be aware of actor isolation and reentrancy

### Structured Concurrency
- Use `async let` for concurrent independent operations
- Use `TaskGroup` for dynamic concurrent operations
- Properly propagate cancellation through task hierarchies

## SwiftUI Best Practices

### View Structure
- Keep views small and focused
- Extract reusable components into separate views
- Use `@State` for local view state
- Use `@StateObject` for view-owned observable objects
- Use `@ObservedObject` or `@EnvironmentObject` for shared objects

### ViewModels (MVVM)
- ViewModels should conform to `ObservableObject`
- Use `@Published` for properties that trigger view updates
- Keep business logic in ViewModels, not in Views
- ViewModels should not import SwiftUI

### Performance
- Use `Identifiable` for list items to optimize rendering
- Avoid expensive computations in view body; use computed properties or ViewModels
- Use `.task` or `.onAppear` for lifecycle-dependent async work

## Safety & Validation

### Precondition Checks
```swift
func performCoding() async throws {
    // Validate preconditions
    guard isChargerConnected else {
        throw CodingError.preflightCheckFailed(.chargerNotConnected)
    }
    
    guard isLinkStable else {
        throw CodingError.preflightCheckFailed(.unstableConnection)
    }
    
    // Create backup before write
    try await createBackup()
    
    // Perform operation
    try await executeCoding()
}
```

### Input Validation
- Validate all external inputs (VIN format, chassis codes, etc.)
- Use guard statements to fail early
- Provide clear error messages for validation failures

## Testing

### Test Structure
- Name tests descriptively: `test_vehicleConnection_whenNetworkFails_throwsError`
- Use Given-When-Then pattern in test bodies
- Mock external dependencies (network, file system)
- Test both success and failure paths

### XCTest Usage
```swift
func test_backupCreation_beforeCoding_createsValidBackup() async throws {
    // Given
    let mockTransport = MockTransport()
    let codingService = CodingService(transport: mockTransport)
    
    // When
    let backup = try await codingService.createBackup(for: mockVIN)
    
    // Then
    XCTAssertNotNil(backup)
    XCTAssertEqual(backup.vin, mockVIN)
    XCTAssertTrue(backup.isValid)
}
```

## Documentation

### Comments
- Use `///` for documentation comments on public APIs
- Include parameter descriptions with `- Parameter name: description`
- Include return value descriptions with `- Returns: description`
- Document throwing behavior with `- Throws: error type and conditions`
- Include usage examples for complex APIs with `/// # Example:`

### Inline Comments
- Use `//` for implementation notes
- Explain "why" not "what" (code should be self-documenting)
- Mark TODOs clearly: `// TODO: Implement retry logic`
- Mark important safety notes: `// SAFETY: Must verify backup before proceeding`

## Specific to This Project

### Transport Layer
- Always implement timeout handling
- Use `Network.framework` for ENET connections
- Handle connection quality checks (latency, packet loss)
- Provide simulated/mock transport for testing

### Protocol Layer (UDS/KWP)
- Follow ISO 14229 specifications for UDS
- Implement proper session management
- Handle service-specific timeouts
- Parse diagnostic responses according to spec

### Coding Operations
- ALWAYS create backups before writes
- Validate chassis/I-step compatibility
- Verify CAFD presence and version
- Log all operations with VIN and timestamp
- Implement rollback on failure

### Data Parsing
- Handle BMW-specific formats (CAFD, NCD, SVT)
- Validate data integrity (checksums, hashes)
- Handle version differences gracefully
- Cache parsed definitions appropriately

## Code Smells to Avoid

### Anti-patterns
- Don't use force unwrapping (`!`) unless absolutely certain
- Avoid optional chaining abuse; handle optionals explicitly
- Don't use `try!` or `try?` for error-prone operations
- Avoid massive view bodies; extract subviews
- Don't mix UI and business logic
- Avoid global mutable state

### Performance Issues
- Don't perform synchronous I/O on main thread
- Avoid excessive view updates
- Don't create excessive closures in tight loops
- Be careful with retain cycles in closures (use `[weak self]` or `[unowned self]`)

### Safety Issues
- Never skip validation checks
- Don't hardcode timeouts that should be configurable
- Avoid race conditions with proper synchronization
- Don't ignore error cases

## Common Patterns for This Project

### Backup Pattern
```swift
protocol BackupService {
    func createBackup(for vin: VIN, module: ECUModule) async throws -> Backup
    func verifyBackup(_ backup: Backup) async throws -> Bool
    func restoreBackup(_ backup: Backup) async throws
}
```

### Preflight Pattern
```swift
struct PreflightChecker {
    private let connectionMonitor: ConnectionMonitor
    
    func checkPreconditions() async throws {
        guard connectionMonitor.isChargerConnected else {
            throw PreflightError.chargerNotConnected
        }
        
        guard connectionMonitor.isLinkStable else {
            throw PreflightError.unstableConnection
        }
        
        // More checks...
    }
}
```

### Coding Operation Pattern
```swift
func performCodingOperation() async throws {
    try await preflightCheck()
    let backup = try await createBackup()
    
    do {
        try await executeCoding()
        try await verifyResult()
    } catch {
        try await restoreBackup(backup)
        throw error
    }
}
```
