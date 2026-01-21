# Architecture

## Layered Design
1. **Transport Layer**
   - ENET over Wi‑Fi/USB-C/Lightning via `Network.framework`.
   - Connection quality checks (latency, packet loss) and battery voltage gating before writes.
   - Pluggable transports to allow mock/simulated mode.

2. **Protocol Layer**
   - UDS/KWP services, ISO-TP framing as needed by target ECUs.
   - Session control, security access, timing/timeout management.
   - Error handling with retries and module-specific behavior.

3. **BMW Coding Layer**
   - VO/FA parsing & validation (SALAPA/HO-WORT), option compatibility, I-step awareness.
   - FDL handling (CAFD/NCD parse, parameter mapping, validation).
   - SVT handling (SWFL/BTLD/CAFD versions), diff support.
   - Backup/restore flows with integrity checks (hashes).

4. **Features Layer**
   - DTC: read/clear with structured categories and OEM-like descriptions.
   - VO Coding: apply VO changes to target modules with preflight and backups.
   - FDL Editor: scoped edits with validation and guardrails; revert/restore path.
   - Compare: SVT/NCD tree diff, change preview.
   - Presets (“Cheat”): curated FDL/VO bundles, rendered as explicit changes.
   - Remote Utility: secure file exchange; no direct vehicle control.

5. **App/UI Layer (SwiftUI + MVVM)**
   - Flows: Connect, Scan, Diagnostics, Compare, Presets, Backup/Restore.
   - State: connection/session, vehicle profile, operation status, logs.
   - Safety UX: preflight checklist, confirmations, progress, failure handling.

## Data & Persistence
- **Definitions bundle:** versioned CAFD/NCD schemas, VO option metadata, compatibility tables (by chassis/I-step).
- **Persistence:** Core Data/SQLite for vehicles, sessions, logs, cached definitions.
- **Versioning:** Track I-step and CAFD versions; migrations for definition updates.

## Safety & Guardrails
- Preflight: charger connected, stable link, ignition state, latency/throughput OK.
- Mandatory backup before write; one-tap restore; hash verification.
- Compatibility gates: restrict supported chassis/modules; block unknown CAFD.
- Timeouts/retries tuned per service/module; fail-safe abort with clear messaging.
- Audit log: VIN, operations, timestamps, outcomes.

## Observability
- Structured logging (per layer); in-app log viewer.
- Optional telemetry flags (off by default) for non-PII health metrics.

## Testing Strategy
- Simulated transport and ECU responders for offline tests.
- Golden sample CAFD/NCD/VO fixtures for parsing/diff tests.
- Integration tests for UDS flows with timeouts and retries.
