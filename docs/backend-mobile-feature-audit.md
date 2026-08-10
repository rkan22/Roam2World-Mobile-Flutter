# Backend → Mobile Feature Parity Audit

Status legend: `CONNECTED` = mobile has a concrete integration path, `PARTIAL` = some backend capability is represented but not the whole backend surface, `MISSING` = no verified mobile integration yet.

This audit is intentionally based on real backend/mobile code only. It does not assume parity from similarly named screens.

## Core mobile commerce

| Area | Backend surface | Mobile status | Notes |
|---|---|---|---|
| Authentication | `/api/v1/mobile/auth/login/`, `/api/v1/auth/refresh/` | CONNECTED | JWT login + refresh are implemented in `AuthRepository` / `ApiClient`. |
| Role dashboard (reseller/dealer) | `/api/v1/mobile/dashboard/` | CONNECTED | Live reseller/dealer dashboard path exists. |
| Admin dashboard | `/api/v1/mobile/admin/dashboard/` | PARTIAL | Backend has a dedicated admin endpoint. Mobile role-aware wiring is being added separately; backend response shape differs from reseller/dealer dashboard. |
| Packages/catalog | `/api/v1/mobile/packages/`, `/featured/` | CONNECTED | Catalog integration exists; pagination support has been added. |
| Orders | `/api/v1/mobile/orders/`, order detail | CONNECTED | Read/detail/create flows exist in mobile repositories/screens. |
| eSIM inventory/detail | `/api/v1/mobile/esims/`, detail | CONNECTED | Mobile eSIM list/detail exists. |
| Wallet | `/api/v1/mobile/wallet/` | CONNECTED | Real wallet data path exists. |
| Wallet transactions | `/api/v1/mobile/transactions/` | CONNECTED | Transaction history exists. |
| Reseller top-up request | `/api/v1/mobile/wallet/requests/` | CONNECTED | Mobile uses request semantics rather than fake direct card funding. |
| Dealer balance request | `/api/v1/resellers/dealer-balance/request_balance/` | CONNECTED | Dealer request flow exists. |
| Notifications | `/api/v1/mobile/notifications/` + read/unread/read-all | CONNECTED | Inbox/read state integration exists. |

## B2B management

| Area | Backend surface | Mobile status | Notes |
|---|---|---|---|
| Dealer network | reseller/dealer management endpoints | CONNECTED | Real dealer network workspace exists. |
| Pricing rules | `/api/v1/pricing-rules/` | CONNECTED | CRUD integration exists for role-scoped pricing. |
| Notification rules | `/api/v1/notifications/rules/` | CONNECTED | Server fetch/save path exists. |
| SIM converter | `/api/v1/sim-converter/...` | CONNECTED | History + activation-code parsing exist; mobile does not fake hardware programming. |
| Operations center | failed orders / provider operation logs / webhook logs / audit logs | PARTIAL | Operations workspace exists, but backend operational/admin surface is larger than the current mobile endpoint set. |
| Reports | dashboard/orders-backed reporting + backend report endpoints | PARTIAL | Mobile reporting exists, but dedicated backend admin reports/system-health surfaces are not all represented. |
| Finance ledger | wallet transaction sources | PARTIAL | Role ledger is present, but admin wallet operations are broader than the current mobile surface. |

## Confirmed backend capabilities not yet fully represented in mobile

The backend exposes additional mobile/admin functionality beyond the current `ApiEndpoints` file and current screens. These areas require explicit mobile decisions and integration rather than assuming they are already covered.

| Area | Status | Backend evidence / expected work |
|---|---|---|
| Admin resellers workspace | MISSING/PARTIAL | Dedicated `/api/v1/mobile/admin/resellers/` endpoint exists; verify whether current mobile Clients/Dealer Network screens provide equivalent admin controls. |
| Admin dealers workspace | MISSING/PARTIAL | Dedicated `/api/v1/mobile/admin/dealers/` endpoint exists; mobile needs role-correct admin management UX if parity is required. |
| Admin orders workspace | PARTIAL | Dedicated `/api/v1/mobile/admin/orders/` exists in addition to generic mobile order APIs. |
| Admin pricing workspace | PARTIAL | Dedicated `/api/v1/mobile/admin/pricing/` plus markup update endpoints exist; current pricing rules do not automatically imply full admin parity. |
| Admin reports | MISSING/PARTIAL | `/api/v1/mobile/admin/reports/` exists. |
| Admin system health | MISSING | `/api/v1/mobile/admin/system-health/` exists. |
| Admin activity logs | MISSING | `/api/v1/mobile/admin/activity-logs/` exists. |
| Admin support tickets | MISSING | `/api/v1/mobile/admin/support-tickets/` exists. |
| Admin WhatsApp workspace | MISSING | Backend exposes `/api/v1/mobile/admin/whatsapp/`. |
| Provider retry operations | MISSING | Backend has a dedicated `mobile_admin_provider_retry_urls.py` module. |
| B2B routing admin | MISSING | Backend has a dedicated `mobile_b2b_routing_admin_urls.py` module. |
| Compatibility tools | MISSING | Backend has a dedicated compatibility URL module; no verified mobile counterpart yet. |
| Manual fulfillment | MISSING | Backend has a dedicated manual fulfillment URL module; no verified mobile counterpart yet. |
| Provider callback logs | MISSING | Backend has a dedicated provider callback log URL module. |
| Worldmove/provider-specific operations | PARTIAL | Backend contains provider-specific Worldmove/mobile top-up capabilities; mobile parity needs to be audited per supported provider and role. |
| TGT mobile checks/renewals | PARTIAL | Backend has dedicated TGT mobile check/renew endpoints; verify full mobile exposure and role rules. |
| Admin wallet approve/reject/adjust/refund/delete flows | PARTIAL/MISSING | Backend provides approval and administrative wallet action endpoints beyond basic wallet/top-up requests. |
| Device token / push registration | MISSING/PARTIAL | Backend exposes `/api/v1/mobile/device-token/`; verify current app registration path. |
| eSIM history | MISSING/PARTIAL | Backend exposes mobile eSIM history endpoints separately from current eSIM inventory/detail. |

## High-priority implementation order

1. **Admin parity first** — admin dashboard, admin orders/resellers/dealers, reports, system health, activity logs, support.
2. **Operational controls** — provider retry, callback logs, B2B routing, failed-order handling.
3. **Commercial controls** — admin pricing/markup, wallet approvals/actions, reseller/dealer financial controls.
4. **Provider-specific mobile actions** — TGT/Worldmove and any other backend-supported provider workflows that are valid for mobile.
5. **Secondary platform functions** — compatibility, manual fulfillment, push/device registration, eSIM history.

## Guardrails

- Do not add UI for a backend function until its role/permissions, request payload, and response shape are verified.
- Do not fabricate metrics, wallet balances, order data, QR data, provider status, or operational outcomes.
- Admin, reseller, and dealer endpoints must remain role-aware; do not reuse a tenant endpoint for admin when a dedicated admin endpoint exists.
- Keep the approved dashboard layout intact while replacing placeholders/missing values with real backend fields.

## Next audit pass

For each `MISSING` / `PARTIAL` item, inspect the backend URL module and view implementation, then record:

- HTTP method and path
- allowed roles / permission guard
- request payload
- response shape
- current mobile repository/service counterpart
- required screen/action
- error/empty/loading behavior

This file should be updated as each integration lands so that backend/mobile parity is measurable instead of assumed.
