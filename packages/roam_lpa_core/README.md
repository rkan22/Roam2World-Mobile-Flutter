# roam_lpa_core

Small, transport-neutral package that defines the reusable boundary for Roam2World LPA operations.

## Why this exists

NekokoLPA2 is currently a full Flutter application. Pulling its root package into Roam2World would also pull UI, scanner, persistence, BLE, notifications and other app concerns. Instead, reusable profile-management code is extracted incrementally behind these contracts.

## Transport policy

1. `androidSystem`: Android `EuiccManager`, preferred where supported.
2. `nekokoExternal`: supported `lpa:` handoff to the installed NekokoLPA2 app.
3. `nekokoEmbedded`: future in-process adapter using extracted Nekoko ProfileManager / ES9+ / ASN.1 / APDU logic.

## Embedded extraction boundary

The embedded transport must depend only on core protocol code and an `EuiccChannel` implementation. It must not import Nekoko screens, Riverpod app state, scanner, SQLite, notifications, BLE UI or branding assets.

The first extraction target is protocol parsing + APDU/profile orchestration. Android logical-channel access remains platform-specific and is injected through `EuiccChannel`.
