require('dotenv').config();

const express = require('express');
const { config } = require('./config');
const { EntitlementStore } = require('./store');
const { GooglePlayVerifier } = require('./googlePlayVerifier');

const app = express();
app.use(express.json({ limit: '1mb' }));

const store = new EntitlementStore(config.dataFile);
const verifier = new GooglePlayVerifier({
  packageName: config.packageName,
  lifetimeProductIds: config.lifetimeProductIds,
});

function requireApiKey(req, res, next) {
  if (!config.apiKey) return next();
  const value = req.header('x-entitlement-api-key');
  if (value !== config.apiKey) {
    return res.status(401).json({
      error: 'unauthorized',
      message: 'Missing or invalid API key',
    });
  }
  return next();
}

function requireAdminApiKey(req, res, next) {
  if (!config.adminApiKey) {
    return res.status(503).json({
      error: 'admin_key_not_configured',
      message: 'Admin API key is not configured',
    });
  }

  const value = req.header('x-entitlement-admin-api-key');
  if (value !== config.adminApiKey) {
    return res.status(401).json({
      error: 'unauthorized_admin',
      message: 'Missing or invalid admin API key',
    });
  }
  return next();
}

function validateVerifyBody(req, res, next) {
  const { appUserId, productId, purchaseToken, packageName } = req.body || {};

  if (!appUserId || typeof appUserId !== 'string') {
    return res.status(400).json({
      error: 'invalid_request',
      message: 'appUserId is required',
    });
  }

  if (!productId || typeof productId !== 'string') {
    return res.status(400).json({
      error: 'invalid_request',
      message: 'productId is required',
    });
  }

  if (!purchaseToken || typeof purchaseToken !== 'string') {
    return res.status(400).json({
      error: 'invalid_request',
      message: 'purchaseToken is required',
    });
  }

  if (packageName && typeof packageName !== 'string') {
    return res.status(400).json({
      error: 'invalid_request',
      message: 'packageName must be a string',
    });
  }

  return next();
}

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'wealth-dial-entitlements',
    time: new Date().toISOString(),
  });
});

app.post(
    '/v1/verify/google-play',
    requireApiKey,
    validateVerifyBody,
    async (req, res) => {
      const { appUserId, productId, purchaseToken, packageName } = req.body;
      const tokenHash = store.hashToken(purchaseToken);
      const existing = store.getPurchaseByTokenHash(tokenHash);

      if (
        existing &&
      existing.appUserId !== appUserId &&
      !config.allowTokenTransfer
      ) {
        return res.status(409).json({
          error: 'token_bound_to_other_user',
          message:
          'Purchase token already linked to another app user id. Set ALLOW_TOKEN_TRANSFER=true to override.',
        });
      }

      const verification = await verifier.verify({
        productId,
        purchaseToken,
        packageName,
      });

      if (!verification.isValid) {
        return res.status(400).json({
          verified: false,
          status: verification.status,
          reason: verification.storePayload?.error || 'verification_failed',
        });
      }

      const result = store.upsertVerification({
        appUserId,
        productId,
        purchaseToken,
        platform: 'android',
        verificationResult: verification,
      });

      return res.status(200).json({
        verified: true,
        appUserId,
        tokenHash: result.tokenHash,
        entitlement: result.entitlement,
      });
    },
);

app.get('/v1/entitlements/:appUserId', requireApiKey, (req, res) => {
  const { appUserId } = req.params;
  const entitlement = store.getEntitlement(appUserId);

  if (!entitlement) {
    return res.status(404).json({
      found: false,
      entitlement: null,
    });
  }

  return res.status(200).json({
    found: true,
    appUserId,
    entitlement,
  });
});

app.post(
    '/v1/admin/backfill/twitch',
    requireApiKey,
    requireAdminApiKey,
    (req, res) => {
      const { appUserId, twitchUserId, expiresAt } = req.body || {};
      if (!appUserId || typeof appUserId !== 'string') {
        return res.status(400).json({
          error: 'invalid_request',
          message: 'appUserId is required',
        });
      }

      let normalizedExpiresAt = null;
      if (expiresAt != null) {
        const parsed = new Date(expiresAt);
        if (Number.isNaN(parsed.valueOf())) {
          return res.status(400).json({
            error: 'invalid_request',
            message: 'expiresAt must be a valid ISO-8601 date when provided',
          });
        }
        normalizedExpiresAt = parsed.toISOString();
      } else {
        const fallback = new Date();
        fallback.setUTCDate(fallback.getUTCDate() + config.twitchBackfillDays);
        normalizedExpiresAt = fallback.toISOString();
      }

      const result = store.upsertManualEntitlement({
        appUserId,
        source: 'twitch_subscriber',
        productId: 'twitch_subscriber',
        isLifetime: false,
        expiresAt: normalizedExpiresAt,
        metadata: {
          twitchUserId: twitchUserId || null,
          reason: 'admin_twitch_backfill',
        },
      });

      return res.status(200).json({
        ok: true,
        appUserId,
        tokenHash: result.tokenHash,
        entitlement: result.entitlement,
      });
    },
);

app.use((error, _req, res, _next) => {
  console.error('[Server] Unhandled error:', error);
  res.status(500).json({
    error: 'internal_error',
    message: 'Unexpected server error',
  });
});

app.listen(config.port, () => {
  console.log(
      `[Entitlements] Listening on :${config.port} (package=${config.packageName})`,
  );
});
