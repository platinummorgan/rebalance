# Entitlement Backend Setup (P1-01)

This setup adds real purchase verification while keeping all financial data local-only.

## What is sent to backend
- Anonymous `appUserId`
- `productId`
- Play `purchaseToken`
- Android `packageName`

## What is NOT sent
- Accounts
- Liabilities
- Income
- Expenses
- Any portfolio totals/details

## Backend Location
- `backend/entitlements/`

## Run backend locally
```bash
cd backend/entitlements
npm install
cp .env.example .env
npm run dev
```

## Configure app to use backend
Pass dart defines when running/building:
```bash
flutter run \
  --dart-define=ENTITLEMENT_API_BASE_URL=https://your-entitlement-host \
  --dart-define=ENTITLEMENT_API_KEY=your_api_key
```

Release build example:
```bash
flutter build appbundle --release \
  --dart-define=ENTITLEMENT_API_BASE_URL=https://your-entitlement-host \
  --dart-define=ENTITLEMENT_API_KEY=your_api_key
```

## Optional debug-only bypass
For local development only:
```bash
flutter run --dart-define=ALLOW_UNVERIFIED_PURCHASES=true
```

Never enable this in production.

## Production deployment
See [ENTITLEMENT_DEPLOYMENT_RUNBOOK.md](ENTITLEMENT_DEPLOYMENT_RUNBOOK.md) for
Cloud Run deployment, secret setup, and live purchase validation steps.
