# Safety & Guardrails

## Preflight Checklist (writes)
- Charger connected; stable link (latency/packet loss thresholds).
- Ignition state verified; battery voltage OK.
- Supported chassis/I-step; known CAFD present.
- Backup path writable; storage available.

## During Operations
- Timeouts/retries per module; fail-safe abort on repeated errors.
- Progress + logs per step; user-confirmed continuation.
- Prevent mixed partial states (module-by-module checkpoints where possible).

## Backups & Restore
- Mandatory backup before any write; hash and metadata (VIN, module, CAFD version, timestamp).
- One-tap restore; verify integrity before applying.
- Store locally; allow export for safekeeping.

## Scope & Compatibility
- Explicit support matrix by chassis/I-step.
- Block unknown/unsupported CAFD or missing definitions.
- Presets only for validated combinations; surface risk level.

## UX Warnings
- Explain what changes will be applied (VO/FDL deltas).
- Require explicit confirmation for each coding action.
- Show recovery guidance if connection drops.
