const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

class EntitlementStore {
  constructor(filePath) {
    this.filePath = filePath;
    this.db = this._load();
  }

  _load() {
    try {
      if (!fs.existsSync(this.filePath)) {
        return {
          version: 1,
          users: {},
          purchasesByTokenHash: {},
        };
      }
      const raw = fs.readFileSync(this.filePath, 'utf8');
      const parsed = JSON.parse(raw);
      return {
        version: 1,
        users: parsed.users || {},
        purchasesByTokenHash: parsed.purchasesByTokenHash || {},
      };
    } catch (error) {
      console.error('[Store] Failed loading db, starting clean:', error);
      return {
        version: 1,
        users: {},
        purchasesByTokenHash: {},
      };
    }
  }

  _persist() {
    const dir = path.dirname(this.filePath);
    fs.mkdirSync(dir, { recursive: true });
    const tempPath = `${this.filePath}.tmp`;
    fs.writeFileSync(tempPath, JSON.stringify(this.db, null, 2), 'utf8');
    fs.renameSync(tempPath, this.filePath);
  }

  hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  getPurchaseByTokenHash(tokenHash) {
    return this.db.purchasesByTokenHash[tokenHash] || null;
  }

  upsertVerification({
    appUserId,
    productId,
    purchaseToken,
    platform,
    verificationResult,
  }) {
    const tokenHash = this.hashToken(purchaseToken);
    const nowIso = new Date().toISOString();

    const tokenRecord = {
      tokenHash,
      appUserId,
      platform,
      productId,
      status: verificationResult.status,
      isPro: verificationResult.isPro,
      isLifetime: verificationResult.isLifetime,
      expiresAt: verificationResult.expiresAt || null,
      verifiedAt: nowIso,
      storePayload: verificationResult.storePayload,
    };

    this.db.purchasesByTokenHash[tokenHash] = tokenRecord;

    if (!this.db.users[appUserId]) {
      this.db.users[appUserId] = {
        appUserId,
        createdAt: nowIso,
        updatedAt: nowIso,
        tokenHashes: [],
        entitlement: null,
      };
    }

    const user = this.db.users[appUserId];
    if (!user.tokenHashes.includes(tokenHash)) {
      user.tokenHashes.push(tokenHash);
    }
    user.updatedAt = nowIso;
    user.entitlement = this.computeEntitlement(appUserId);

    this._persist();
    return { tokenHash, entitlement: user.entitlement };
  }

  upsertManualEntitlement({
    appUserId,
    source,
    productId,
    isLifetime = false,
    expiresAt = null,
    metadata = {},
  }) {
    const nowIso = new Date().toISOString();
    const syntheticToken = `manual:${source}:${appUserId}:${productId}`;
    const tokenHash = this.hashToken(syntheticToken);

    const tokenRecord = {
      tokenHash,
      appUserId,
      platform: 'manual',
      productId,
      status: isLifetime ? 'active_lifetime' : 'active_subscription',
      isPro: true,
      isLifetime,
      expiresAt: isLifetime ? null : expiresAt,
      verifiedAt: nowIso,
      storePayload: {
        source,
        manualBackfill: true,
        ...metadata,
      },
    };

    this.db.purchasesByTokenHash[tokenHash] = tokenRecord;

    if (!this.db.users[appUserId]) {
      this.db.users[appUserId] = {
        appUserId,
        createdAt: nowIso,
        updatedAt: nowIso,
        tokenHashes: [],
        entitlement: null,
      };
    }

    const user = this.db.users[appUserId];
    if (!user.tokenHashes.includes(tokenHash)) {
      user.tokenHashes.push(tokenHash);
    }
    user.updatedAt = nowIso;
    user.entitlement = this.computeEntitlement(appUserId);

    this._persist();
    return { tokenHash, entitlement: user.entitlement };
  }

  getEntitlement(appUserId) {
    const user = this.db.users[appUserId];
    if (!user) return null;
    return user.entitlement || this.computeEntitlement(appUserId);
  }

  computeEntitlement(appUserId) {
    const user = this.db.users[appUserId];
    if (!user) return null;

    const records = user.tokenHashes
        .map((hash) => this.db.purchasesByTokenHash[hash])
        .filter(Boolean);

    const now = new Date();
    let bestActive = null;

    for (const record of records) {
      if (record.isLifetime && record.isPro) {
        bestActive = {
          isPro: true,
          isLifetime: true,
          status: 'active_lifetime',
          productId: record.productId,
          expiresAt: null,
          lastVerifiedAt: record.verifiedAt,
        };
        break;
      }

      if (!record.isPro) continue;
      if (!record.expiresAt) continue;

      const expiry = new Date(record.expiresAt);
      if (Number.isNaN(expiry.valueOf())) continue;
      if (expiry <= now) continue;

      if (!bestActive || new Date(bestActive.expiresAt) < expiry) {
        bestActive = {
          isPro: true,
          isLifetime: false,
          status: 'active_subscription',
          productId: record.productId,
          expiresAt: record.expiresAt,
          lastVerifiedAt: record.verifiedAt,
        };
      }
    }

    if (bestActive) {
      return bestActive;
    }

    return {
      isPro: false,
      isLifetime: false,
      status: 'inactive',
      productId: null,
      expiresAt: null,
      lastVerifiedAt: new Date().toISOString(),
    };
  }
}

module.exports = { EntitlementStore };
