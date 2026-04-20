const path = require('path');

const APP_ROOT = path.resolve(__dirname, '..');

function normalizeBaseUrl(url) {
  if (!url) return '';
  return url.endsWith('/') ? url.slice(0, -1) : url;
}

const config = {
  port: Number(process.env.PORT || 8080),
  apiKey: process.env.ENTITLEMENT_API_KEY || '',
  adminApiKey: process.env.ENTITLEMENT_ADMIN_API_KEY || '',
  packageName: process.env.GOOGLE_PLAY_PACKAGE_NAME || 'com.wealthdial.app',
  lifetimeProductIds: (process.env.GOOGLE_PLAY_LIFETIME_PRODUCT_IDS ||
          'founder_lifetime')
      .split(',')
      .map((id) => id.trim())
      .filter(Boolean),
  allowTokenTransfer: process.env.ALLOW_TOKEN_TRANSFER === 'true',
  dataFile: process.env.ENTITLEMENT_DB_PATH ||
      path.join(APP_ROOT, 'data', 'entitlements.json'),
  twitchBackfillDays: Number(process.env.TWITCH_BACKFILL_DAYS || 32),
  baseUrl: normalizeBaseUrl(process.env.PUBLIC_BASE_URL || ''),
};

module.exports = { config };
