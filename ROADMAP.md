# Roadmap

## Phase 1 (Read-Only, Safer)
- ENET transport + connection quality checks.
- Vehicle detect: VIN, VO/FA decode, module inventory.
- DTC read/clear with OEM-like descriptions.
- SVT/NCD load and compare (tree diff).
- Preset/“cheat” previews (no write).
- Session logging and backup format definition.

## Phase 2 (Controlled Write)
- Mandatory backups with hash verification.
- VO coding for supported modules (gated by chassis/I-step).
- FDL edits with validation and revert.
- Preset-driven coding (explicit changes, confirmations).
- Error handling tuned per module; restore workflow.

## Phase 3 (Advanced/Remote)
- Remote Utility for secure file exchange (no direct car control).
- Batch jobs with dry-run and dependency checks.
- Broader chassis/I-step coverage with curated definitions.
- Telemetry/health (opt-in, non-PII).

## Non-Goals (initial)
- Direct remote vehicle control.
- Unsupported chassis/modules without verified coverage.
