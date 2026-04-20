const { google } = require('googleapis');

class GooglePlayVerifier {
  constructor({ packageName, lifetimeProductIds }) {
    this.packageName = packageName;
    this.lifetimeProductIds = new Set(lifetimeProductIds);
    this._publisher = null;
  }

  async _getPublisher() {
    if (this._publisher) return this._publisher;

    const auth = new google.auth.GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const authClient = await auth.getClient();
    this._publisher = google.androidpublisher({
      version: 'v3',
      auth: authClient,
    });

    return this._publisher;
  }

  async verify({ productId, purchaseToken, packageName }) {
    const publisher = await this._getPublisher();
    const resolvedPackageName = packageName || this.packageName;
    const isLifetimeProduct = this.lifetimeProductIds.has(productId);

    if (isLifetimeProduct) {
      return this._verifyProduct({
        publisher,
        packageName: resolvedPackageName,
        productId,
        purchaseToken,
      });
    }

    return this._verifySubscription({
      publisher,
      packageName: resolvedPackageName,
      productId,
      purchaseToken,
    });
  }

  async _verifyProduct({ publisher, packageName, productId, purchaseToken }) {
    try {
      const response = await publisher.purchases.products.get({
        packageName,
        productId,
        token: purchaseToken,
      });
      const data = response.data || {};
      const purchaseState = Number(data.purchaseState ?? -1);
      const acknowledged = Number(data.acknowledgementState ?? 0) === 1;
      const isPurchased = purchaseState === 0;

      return {
        isValid: isPurchased,
        isPro: isPurchased,
        isLifetime: isPurchased,
        expiresAt: null,
        status: isPurchased ? 'active_lifetime' : 'invalid_lifetime',
        storePayload: {
          type: 'product',
          purchaseState,
          acknowledged,
          consumptionState: data.consumptionState ?? null,
        },
      };
    } catch (error) {
      return this._formatError(error);
    }
  }

  async _verifySubscription({
    publisher,
    packageName,
    productId,
    purchaseToken,
  }) {
    try {
      const response = await publisher.purchases.subscriptionsv2.get({
        packageName,
        token: purchaseToken,
      });
      const data = response.data || {};
      const lineItems = Array.isArray(data.lineItems) ? data.lineItems : [];
      const matchingLine = lineItems.find((item) => item.productId === productId) ||
          lineItems[0] ||
          null;

      const expiryTime = matchingLine?.expiryTime || null;
      const subscriptionState = data.subscriptionState || 'UNKNOWN';
      const activeStates = new Set([
        'SUBSCRIPTION_STATE_ACTIVE',
        'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
      ]);
      const isPro = activeStates.has(subscriptionState);

      return {
        isValid: true,
        isPro,
        isLifetime: false,
        expiresAt: expiryTime,
        status: subscriptionState.toLowerCase(),
        storePayload: {
          type: 'subscription',
          subscriptionState,
          expiryTime,
          latestOrderId: data.latestOrderId || null,
          lineItemProductId: matchingLine?.productId || null,
        },
      };
    } catch (error) {
      return this._formatError(error);
    }
  }

  _formatError(error) {
    const status = error?.code || error?.response?.status || 500;
    const message = error?.message || 'Verification failed';
    return {
      isValid: false,
      isPro: false,
      isLifetime: false,
      expiresAt: null,
      status: `verification_error_${status}`,
      storePayload: {
        error: message,
        code: status,
      },
    };
  }
}

module.exports = { GooglePlayVerifier };
