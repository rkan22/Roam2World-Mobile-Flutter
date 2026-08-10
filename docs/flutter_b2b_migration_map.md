# Roam2World B2B Flutter Migration Map

This document defines the migration contract from `rkan22/roam2world-panels-frontend` to the Flutter mobile application.

## Source of truth

- Web frontend: product functions, role permissions, business flows, route coverage.
- Flutter design system: mobile visual language and reusable native components.
- Mobile API: only real server-backed values may be rendered. Missing web KPIs must not be fabricated.
- `vendor/NekokoLPA2`: eSIM/LPA integration dependency; keep isolated from UI migration work.

## Roles

### Admin
Dashboard, Customers & Orders, Transactions, Balance Top-ups, Statements, Credit Management, Resellers, Analytics, Unified Catalog, Catalog Governance, Smart Routing, Provider Markups, Profitability, Provider Operations, Manual Fulfilment, Operations Center, API/Webhook Logs, Failed Orders, Audit & Access, Notifications, Alert Rules, WhatsApp, Developer Portal, Conversion Tracking, Banners & Ads, Settings.

### Reseller
Dashboard, Unified Catalog, Catalog Controls, Clients, Dealers, SIM/eSIM inventory, Assign eSIM, Usage Query, Renew/Top-up, SIM Converter, Finance Ledger, Dealer Wallet, Dealer Pricing, Coverage, Dealer Performance, Profitability, Operations, Failed Orders, API Logs, Audit Log, Notification Rules, Reports, Profile.

### Dealer
Dashboard, Unified Catalog, Customer Pricing, SIM Converter, Finance Ledger, SIM/eSIM inventory, Orders, Clients, Usage Query, Renew/Top-up, Reports, Profile, Settings.

### Client
Dashboard, My eSIMs, eSIM Detail, QR/Installation, Orders, Reports.

### Public user
Dashboard, Browse Packages, Purchase, Purchase Result, My eSIMs, Orders, Payments, Reports, Profile, Settings.

## Flutter feature target

```text
lib/features/
  auth/
  dashboard/
  catalog/
  packages/
  checkout/
  esims/
  orders/
  customers/
  partners/
  wallet/
  finance/
  pricing/
  reports/
  operations/
  notifications/
  billing/
  developer/
  integrations/
  security/
  marketing/
  support/
  profile/
  settings/
```

## Delivery phases

1. Foundation: design system, app shell, role-aware navigation, authentication.
2. B2B Core: Reseller Dashboard, Catalog, Clients, Dealers, Orders, eSIM Inventory, Assign eSIM, eSIM Detail.
3. Money: Wallet, Ledger, Top-up, Dealer Wallet, Pricing, Statements, Transactions.
4. Advanced B2B: Coverage, Provider Operations, Failed Orders, Profitability, API Logs, Audit, Notifications, Reports.
5. Role completion: Admin, Dealer, Client and Public User variants.

## Implemented foundation slices

### Reseller Dashboard

- Role-specific mobile dashboard screen.
- Period filters backed by the mobile API query (`today`, `7d`, `30d`, `month`, `all`).
- Backward-compatible parsing for legacy flat mobile responses and richer nested B2B dashboard responses.
- Optional revenue, profit, margin, successful order and customer KPIs render only when supplied by the API.
- Wallet, eSIM KPIs, quick actions, recent orders, loading/error/stale states use the shared B2B design system.

### Unified Catalog

- Search and quick destination filters for All, Turkey, Europe and Global.
- Mobile filter bottom sheet for operator, SIM/eSIM type, validity and data allowance.
- Catalog cards surface provider, product kind, data, validity, coverage count, featured state and server-backed price.
- Repository forwards supported filter inputs to the mobile packages endpoint and keeps stale-cache fallback behavior.

### Client Management

- Mobile reseller customer workspace modeled on the web Client Management flow.
- Search plus All / Active / Pending filters.
- Customer summaries are derived only from real mobile order history until a dedicated customer endpoint is available.
- Customer Detail shows lifetime order volume, completed/pending order counts and customer-specific order history.
- New Order actions route back into the Unified Catalog.
- Email, phone and eSIM statistics are intentionally not fabricated when the mobile API does not provide them.

### SIM & eSIM Inventory

- One inventory surface supports both physical SIMs and eSIMs, matching the web B2B inventory model.
- Search plus Active / Pending / Expired / Installed status tabs.
- Mobile filter bottom sheet for provider and line type.
- Inventory cards surface ICCID, provider, package, customer, data/validity, expiry and usage only when supplied by the API.
- Detail screen is capability-aware: physical SIMs do not show QR/LPA controls; eSIMs can show QR, SM-DP+, Matching ID and direct install actions.
- Existing mobile eSIM endpoint remains the source of truth; no usage, QR or expiry values are fabricated.

### Orders & New Order

- Order parsing now supports R2W references, customer/email, ICCID, product type and provider-issued activation data when returned by the mobile API.
- The previous hard-coded demo Order Detail screen was removed; order details now render only the selected real `MobileOrderSummary`.
- Order Detail shows customer assignment, ICCID, type, created time, amount and status, with QR/activation controls only when the backend returns installation data.
- `/orders/detail` requires a real order object and safely redirects to the order list when opened without one.
- Checkout keeps the existing mobile create-order contract but is presented as a B2B Package → Customer → Review flow.
- Final submission is explicit as `Pay & create order`; provisioning remains server/provider driven and no QR is fabricated.

### Finance Ledger & Top-up

- `/wallet` now opens a reseller-specific Finance Ledger workspace rather than the generic wallet screen.
- Wallet balance stays sourced from `/api/v1/mobile/wallet/`; the full transaction ledger is enriched from `/api/v1/mobile/transactions/` when available.
- Ledger enrichment is backward-compatible: if the transactions endpoint fails, the wallet still renders its server-provided recent transactions.
- Transaction normalization supports credits, debits, refunds, failed states, references, providers and related order numbers without fabricating missing values.
- Finance KPIs include total debits, credits, refunds, failed transaction count and net movement calculated only from returned ledger rows.
- Search plus All / Credits / Debits / Refunds / Failed filters match the B2B web finance workflow.
- Top-up requests use `/api/v1/mobile/wallet/requests/` with quick amount presets, custom amount, optional note, error handling and refresh after submission.

### Dealer Network & Wallet

- `/dealers` adds a reseller-focused mobile dealer workspace based on the web Dealer Management and Dealer Wallet flows.
- Dealer cards surface real status, available balance, client count and order count returned by the reseller dealer API.
- Network KPIs include total dealers, active dealers, aggregate dealer balance and pending funding approvals.
- Pending dealer wallet requests can be approved through the existing mobile approval endpoint.
- Dealer wallet credit/debit actions use the existing mobile allocation/modify balance endpoints and never fabricate transfer success.
- Dealer search and Active / Suspended filters are optimized for mobile instead of reproducing the desktop table.
- Dealer edit, suspend/delete and pricing writes remain out of this slice until their exact mobile-safe write contracts are validated.

## Dashboard migration rule

The production reseller dashboard is `lib/features/dashboard/reseller_dashboard_screen.dart`. The older generic/reference dashboards remain available during migration but are not the target for the reseller route.

## Mobile UX rules

- Do not shrink desktop tables into a phone viewport. Convert them to list/card + detail flows.
- Keep primary tasks within 1-2 taps.
- Use bottom sheets for filters/actions when appropriate.
- Preserve role permissions and business rules from the web frontend.
- Use shared design-system components rather than page-local styling.
- Every data screen needs loading, empty, error, stale/offline and success feedback states.
