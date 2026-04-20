# Wealth Dial Entitlement Service

This service verifies Google Play purchases and returns Pro entitlement status.

It does **not** store portfolio/financial records.
It only stores purchase metadata (token hash, product id, expiry/state, app user id).

## Endpoints
- `GET /health`
- `POST /v1/verify/google-play`
- `GET /v1/entitlements/:appUserId`

## Request/Response

### `POST /v1/verify/google-play`
Request body:
```json
{
  "appUserId": "stable-anonymous-id",
  "productId": "pro_monthly",
  "purchaseToken": "token-from-google-play",
  "packageName": "com.wealthdial.app"
}
```

Success response:
```json
{
  "verified": true,
  "appUserId": "stable-anonymous-id",
  "tokenHash": "sha256...",
  "entitlement": {
    "isPro": true,
    "isLifetime": false,
    "status": "active_subscription",
    "productId": "pro_monthly",
    "expiresAt": "2026-04-21T12:00:00Z",
    "lastVerifiedAt": "2026-03-24T16:03:00Z"
  }
}
```

## Setup
1. `cd backend/entitlements`
2. `npm install`
3. `cp .env.example .env`
4. Configure credentials:
   - Option A: `GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json`
   - Option B: rely on runtime IAM (Cloud Run/GKE/Compute metadata credentials)
5. `npm run dev`

## Required Google setup
1. Link Play Console app to Google Cloud project.
2. Enable **Google Play Android Developer API**.
3. Create a service account and grant Play Console permissions:
   - View financial data/order management (or equivalent access needed for purchases API).
4. Use that service account for runtime auth.

## Deployment Notes
- Deploy behind HTTPS.
- Set `ENTITLEMENT_API_KEY` in runtime env and send it from the app using `X-Entitlement-Api-Key`.
- For production, replace local JSON store with managed DB (Postgres/Firestore/etc.).
- Docker build:
  - `docker build -t wealth-dial-entitlements .`
  - `docker run -p 8080:8080 --env-file .env wealth-dial-entitlements`
- Cloud Run deploy helpers:
  - PowerShell: `scripts/deploy_cloud_run.ps1`
  - Bash: `scripts/deploy_cloud_run.sh`

## Security Notes
- Financial data stays local in the app.
- Purchase tokens are persisted as SHA-256 hashes for indexing.
- Verification always happens server-side via Google API.
