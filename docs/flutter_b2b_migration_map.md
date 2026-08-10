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

## Dashboard migration rule

The maintained Flutter dashboard is `lib/features/dashboard/dashboard_screen.dart`. The legacy `dashboard_screen_reference.dart` is not the production target.

The first dashboard iteration uses the existing mobile endpoint (`/api/v1/mobile/dashboard/`) and exposes only values backed by that response. Web-only metrics such as gross profit, margin, provider health, expiring inventory and customer counts should be connected when equivalent mobile API fields/endpoints are available.

## Mobile UX rules

- Do not shrink desktop tables into a phone viewport. Convert them to list/card + detail flows.
- Keep primary tasks within 1-2 taps.
- Use bottom sheets for filters/actions when appropriate.
- Preserve role permissions and business rules from the web frontend.
- Use shared design-system components rather than page-local styling.
- Every data screen needs loading, empty, error, stale/offline and success feedback states.
