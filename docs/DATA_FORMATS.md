# Data Formats Outline

## VO/FA
- Parse SALAPA/HO-WORT and build option list.
- Validate option compatibility; map to modules impacted.
- Track I-step and vehicle series for gating.

## CAFD/NCD
- Parse structures into a schema (parameters, enumerations, ranges).
- Map parameters to user-facing labels and risk levels.
- Preserve original NCD; enable diff vs. modified.

## SVT
- Represent SWFL/BTLD/CAFD versions per ECU.
- Diff to highlight version or presence changes.

## Presets (“Cheats”)
- Curated bundles referencing underlying FDL/VO changes.
- Include applicability (chassis/I-step), risk level, and reversibility.

## Backups
- Metadata: VIN, chassis, I-step, module, CAFD version, timestamp, hashes.
- Payload: original NCD/CAFD segments needed for restore.
