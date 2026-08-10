# eSIM lifecycle parity

This slice connects the Flutter app to verified existing backend endpoints only.

- `GET /api/v1/mobile/esim-history/`
- `GET /api/v1/mobile/esim-history/<esim_id>/`
- `POST /api/v1/mobile/tgt/check-gb/`

The mobile UI exposes backend eSIM lifecycle records and live TGT usage checks for supported `8997` ICCIDs. No local/demo lifecycle records are created. TGT renewal remains a separate follow-up because it requires the backend cascade-pricing validation and charge-confirmation flow.
