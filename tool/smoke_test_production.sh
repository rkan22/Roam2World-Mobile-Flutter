#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://roam2world-panels-backend.onrender.com/api/v1}"
TOKEN="${TOKEN:-}"
CATEGORY="${CATEGORY:-orange_europe}"
PACKAGE_ID="${PACKAGE_ID:-}"
ALLOW_PURCHASE="${ALLOW_PURCHASE:-false}"

if [[ -z "$TOKEN" ]]; then
  echo "TOKEN is required. Keep credentials local and export only the access token." >&2
  echo "Example: TOKEN='...' ./tool/smoke_test_production.sh" >&2
  exit 2
fi

case "$BASE_URL" in
  https://*) ;;
  *) echo "BASE_URL must use HTTPS: $BASE_URL" >&2; exit 2 ;;
esac

if [[ "$BASE_URL" =~ (localhost|127\.0\.0\.1|10\.0\.2\.2|\.local)(:|/|$) ]]; then
  echo "Refusing to run a production smoke test against a local host: $BASE_URL" >&2
  exit 2
fi

AUTH_HEADER="Authorization: Bearer $TOKEN"

get() {
  local path="$1"
  echo
  echo "==> GET $path"
  curl --fail-with-body --silent --show-error \
    "$BASE_URL$path" \
    -H "$AUTH_HEADER" \
    -H 'Accept: application/json'
  echo
}

post_json() {
  local path="$1"
  local body="$2"
  echo
  echo "==> POST $path"
  curl --fail-with-body --silent --show-error \
    -X POST "$BASE_URL$path" \
    -H "$AUTH_HEADER" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    --data "$body"
  echo
}

echo "Roam2World B2B production smoke test"
echo "Base URL: $BASE_URL"
echo "Category: $CATEGORY"

# Authenticated read-only checks.
get '/mobile/b2b/health/'
get '/mobile/b2b/provider-health/'
get '/mobile/b2b/wallet/status/'
get '/mobile/b2b/categories/'
get "/mobile/b2b/packages/?category=$CATEGORY&limit=10"
get '/mobile/b2b/orders/?page=1&page_size=20'

if [[ "$ALLOW_PURCHASE" != "true" ]]; then
  echo
  echo "Read-only smoke test completed."
  echo "Purchase was NOT attempted. To explicitly allow one test purchase, set:"
  echo "  ALLOW_PURCHASE=true PACKAGE_ID='...' CATEGORY='$CATEGORY' TOKEN='...' ./tool/smoke_test_production.sh"
  exit 0
fi

if [[ -z "$PACKAGE_ID" ]]; then
  echo "ALLOW_PURCHASE=true requires PACKAGE_ID." >&2
  exit 2
fi

case "$CATEGORY" in
  orange_europe|orange_world|turkey)
    payload=$(printf '{"category":"%s","package_id":"%s","qty":1,"qrcodeType":2}' "$CATEGORY" "$PACKAGE_ID")
    ;;
  *)
    echo "Automated purchase is intentionally limited to Worldmove eSIM categories." >&2
    echo "Use the backend deploy checklist for TGT/Flexnet/AirHub/eSIMCard flows that require extra fields." >&2
    exit 2
    ;;
esac

post_json '/mobile/b2b/checkout/' "$payload"

echo
echo "Purchase request completed. Verify the returned order_id in Orders and open its detail/QR-LPA screen in the app."
