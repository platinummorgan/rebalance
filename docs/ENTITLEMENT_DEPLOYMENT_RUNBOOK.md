# Entitlement Backend Deployment Runbook (Cloud Run)

Last updated: March 24, 2026

## Goal
Deploy the purchase verification backend with Google Play credentials and connect the app via `--dart-define`.

## Prerequisites
- `gcloud` CLI installed and authenticated.
- Google Cloud project linked to Play Console app.
- Google Play Android Developer API enabled.
- Service account with Play API access granted in Play Console.

## 1. Create API key secret
```bash
echo -n "your_random_api_key_here" | gcloud secrets create ENTITLEMENT_API_KEY --data-file=-
```

If secret already exists:
```bash
echo -n "your_random_api_key_here" | gcloud secrets versions add ENTITLEMENT_API_KEY --data-file=-
```

## 2. Grant runtime secret access
Cloud Run default runtime SA format:
`<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`

```bash
gcloud secrets add-iam-policy-binding ENTITLEMENT_API_KEY \
  --member="serviceAccount:<RUNTIME_SERVICE_ACCOUNT>" \
  --role="roles/secretmanager.secretAccessor"
```

## 3. Deploy service

PowerShell:
```powershell
cd backend/entitlements/scripts
.\deploy_cloud_run.ps1 -ProjectId "<PROJECT_ID>" -Region "<REGION>"
```

Bash:
```bash
cd backend/entitlements/scripts
./deploy_cloud_run.sh <PROJECT_ID> <REGION>
```

## 4. Smoke test deployment
```bash
curl https://<SERVICE_URL>/health
```
Expected:
```json
{"ok":true,"service":"wealth-dial-entitlements",...}
```

## 5. Configure app build/run
Use the deployed URL + same API key value:

```bash
flutter run \
  --dart-define=ENTITLEMENT_API_BASE_URL=https://<SERVICE_URL> \
  --dart-define=ENTITLEMENT_API_KEY=<API_KEY>
```

Release:
```bash
flutter build appbundle --release \
  --dart-define=ENTITLEMENT_API_BASE_URL=https://<SERVICE_URL> \
  --dart-define=ENTITLEMENT_API_KEY=<API_KEY>
```

## 6. Verify with internal test purchase
1. Install internal test build.
2. Purchase `pro_monthly`/`pro_annual` or `founder_lifetime`.
3. Confirm entitlement update in app.
4. Hit backend endpoint for app user id:
   - `GET /v1/entitlements/:appUserId`
5. Confirm status/expiry matches store purchase.

## Notes
- This backend stores entitlement metadata only, not financial records.
- Do not enable `ALLOW_UNVERIFIED_PURCHASES` in production.
