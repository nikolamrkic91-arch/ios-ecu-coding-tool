# GitHub Copilot Instructions - iOS ECU Coding Tool

## Project Overview
This is a dealer-level BMW coding utility for iOS that enables safe, guarded ECU coding with ENET-based connectivity. The project focuses on diagnostics, VO/FA/FDL operations, backups, and controlled coding workflows for BMW vehicles.

## Tech Stack
- **Language**: Swift
- **Framework**: SwiftUI
- **Architecture**: MVVM + Layered Architecture
- **Platform**: iOS (iPhone/iPad)
- **Connectivity**: ENET over Wi-Fi/USB-C/Lightning via Network.framework
- **Protocols**: UDS/KWP for automotive diagnostics

## Core Safety Principles (CRITICAL)
This application deals with automotive ECU coding which can affect vehicle safety and functionality. All code MUST adhere to these principles:

1. **Read-First Philosophy**: Always implement read-only features before write capabilities
2. **Mandatory Backups**: Any write operation MUST require and create backups before execution
3. **Preflight Checks**: Enforce charger connection, stable link, and compatibility verification before any write
4. **Fail-Safe Design**: Operations must fail safely; partial states should be prevented or clearly tracked
5. **Explicit Confirmations**: Users must explicitly confirm all coding actions with clear delta explanations
6. **Comprehensive Logging**: Log all operations with VIN, module, timestamps, and outcomes

## Project Structure
```
Sources/
├── ECUCodingApp/       # SwiftUI app layer (UI, flows, state)
├── ECUCodingCore/      # Core business logic
App/                    # App-specific implementations
Domain/                 # Entities: Vehicles, VO/FA, FDL, presets, compatibility
Comms/                  # Transport (ENET), UDS/KWP services, coding operations
Data/                   # Parsers (CAFD/NCD/SVT), persistence, definitions
Features/               # DTC, VO coding, FDL editor, Compare, Presets
Shared/                 # Logging, errors, telemetry
Tests/                  # Test suites
docs/                   # Documentation (ARCHITECTURE, SAFETY, ROADMAP, etc.)
```

## Development Phases
The project follows a phased approach:
- **Phase 1**: Read-only operations (DTC, VO/FA decode, module inventory, comparisons)
- **Phase 2**: Controlled writes (VO coding, FDL edits with backups and validation)
- **Phase 3**: Advanced features (Remote Utility, batch operations)

When implementing features, respect the phase boundaries and ensure earlier phases are complete.

## Coding Standards

### Swift Style
- Use Swift 5.5+ features (async/await, actors where appropriate)
- Prefer value types (struct) over reference types (class) unless reference semantics are required
- Use clear, descriptive names; avoid abbreviations except for well-known terms (ECU, VIN, UDS, etc.)
- Add documentation comments for public APIs using Swift's `///` syntax
- Use SwiftUI for all UI code (no UIKit unless absolutely necessary)

### Error Handling
- Use Swift's native error handling (throw/try/catch)
- Define specific error types per layer (TransportError, CodingError, etc.)
- Never silently fail; always propagate or log errors
- Provide user-friendly error messages with recovery suggestions

### Architecture Patterns
- Follow MVVM for UI layer (Views + ViewModels)
- Keep layers separated and well-defined:
  - Transport Layer: Network communication only
  - Protocol Layer: UDS/KWP implementation
  - Coding Layer: BMW-specific coding logic
  - Features Layer: User-facing features
  - App/UI Layer: SwiftUI views and state
- Use dependency injection for testability
- Avoid tight coupling between layers; use protocols/interfaces

### Testing
- Write tests for all critical paths, especially:
  - Preflight checks and safety guardrails
  - Backup/restore operations
  - Parsing logic (CAFD, NCD, VO/FA)
  - UDS/KWP protocol handling
- Use simulated transport/ECU responders for offline testing
- Include golden sample fixtures for parser tests
- Test error paths and timeout scenarios

### Safety & Validation
- ALWAYS validate input data (VIN, chassis codes, I-step compatibility)
- ALWAYS check preconditions before write operations
- Implement timeouts and retries appropriately per service
- Verify integrity (hashes) for backups before restore
- Gate features by chassis/I-step compatibility

### Logging & Observability
- Use structured logging with appropriate severity levels
- Log session start/end, connections, operations, and outcomes
- Include relevant context (VIN, module, operation type, timestamp)
- Never log sensitive user data
- Keep logs concise but informative

### Documentation
- Update documentation when adding new features or changing architecture
- Keep README, ARCHITECTURE.md, SAFETY.md, and ROADMAP.md in sync with code
- Document BMW-specific terminology and concepts
- Include examples for complex operations

## BMW/Automotive Specific Guidelines

### Terminology
- **ECU**: Electronic Control Unit (vehicle module)
- **VIN**: Vehicle Identification Number
- **VO/FA**: Fahrzeugauftrag/Vehicle Order (option configuration)
- **FDL**: Funktionsdatenliste (function data/parameters)
- **CAFD**: Central Automotive File Database
- **NCD**: Network Configuration Data
- **SVT**: Software Version Table
- **UDS**: Unified Diagnostic Services (ISO 14229)
- **KWP**: Keyword Protocol 2000
- **ENET**: Ethernet-based diagnostic interface
- **I-step**: Integration step (BMW software release version)
- **DTC**: Diagnostic Trouble Code
- **SALAPA**: BMW option codes
- **HO-WORT**: BMW option words

### Compatibility Checks
- Always validate chassis compatibility before operations
- Check I-step compatibility for CAFD/definitions
- Verify supported modules before attempting coding
- Block operations on unknown or unsupported configurations

### Communication
- Implement proper ISO-TP framing when needed
- Handle UDS session control properly (default, extended diagnostic, etc.)
- Implement security access flows correctly
- Use appropriate timeouts per service (e.g., 5s for standard, longer for flash)
- Handle ECU-specific quirks and error codes

## Things to Avoid
- Never bypass safety checks or backup requirements
- Don't implement write operations without proper validation
- Avoid hardcoded timeouts; make them configurable per service/module
- Don't expose low-level transport/protocol details to UI layer
- Never cache sensitive data (VIN, codes) without proper security
- Don't mix read and write operations in the same feature until Phase 2 is complete
- Avoid blocking the main thread; use async operations for I/O
- Don't add features that allow unsupported chassis/modules without verification

## Dependencies
- Keep external dependencies minimal; prefer Swift standard library and iOS frameworks
- Document any new dependencies and their purpose
- Ensure dependencies are compatible with iOS deployment target
- For BMW-specific data formats, implement parsers internally rather than adding dependencies

## When in Doubt
- Prioritize safety over features
- Read the existing documentation (ARCHITECTURE.md, SAFETY.md, ROADMAP.md)
- Follow the phased approach; don't skip ahead
- Ask for clarification on BMW-specific protocols or formats
- Err on the side of more validation and logging
