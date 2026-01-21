# iOS ECU Coding Tool
Dealer-level BMW coding utility for iOS. Supports ENET-based connectivity, diagnostics, VO/FA/FDL operations, backups, and guarded coding workflows.

## Goals
- Safe, guarded coding with enforced backups and preflight checks.
- Read-focused first (DTC, VO/FA decode, SVT/NCD diff), then controlled writes.
- Modular transport and protocol layers (ENET over Wi‑Fi/USB-C/Lightning).
- Offline-first reference data; online updates only for metadata/definitions.

## Core Features (phased)
- **Phase 1 (read-only):** DTC read/clear with OEM-like descriptions; VO/FA decode; module inventory; SVT/NCD compare; preset “cheat” previews.
- **Phase 2 (controlled write):** VO coding for supported modules; FDL edits with validation and auto-backup/restore; preset-driven coding with guardrails.
- **Phase 3 (advanced/remote):** Remote Utility for secure file exchange (no direct car control); batch jobs with dry-run and dependency checks.

## Safety Principles
- Require charger + stable link for any write; preflight connectivity and latency checks.
- Mandatory backups before write; one-tap restore.
- Compatibility gates by chassis/I-step; surface risk levels per module/operation.
- Full session logging (VIN, modules, operations, timestamps).

## High-Level Architecture
- **App (SwiftUI):** UX, flow, state.
- **Domain:** Vehicles, VO/FA, FDL entities, presets, compatibility.
- **Comms:** Transport adapters (ENET), UDS/KWP services, coding ops, backup/restore.
- **Data:** Parsers (CAFD/NCD/SVT), persistence, definitions bundle.
- **Features:** DTC, VO coding, FDL editor, Compare, Presets, Remote Utility.
- **Shared:** Logging, errors, telemetry toggles.

## Getting Started
1) Target hardware: ENET adapter (Wi‑Fi/USB-C/Lightning).
2) Implement Transport → UDS scaffold; add simulated mode for testing.
3) Add persistence for vehicle profiles, logs, and definitions.
4) Build Phase 1 flows (read-only) before enabling any write.

## Build & Run
```bash
swift test
# Or open in Xcode: File > Open > select repo folder, run ECUCodingApp scheme
```

**Note:** The full package, including the ECUCodingApp executable, requires Xcode on macOS to build since it uses SwiftUI. The ECUCodingCore library can be built and tested on Linux with Swift Package Manager.
