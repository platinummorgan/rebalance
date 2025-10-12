# In-App Purchase Implementation Checklist

## Current Status

### ✅ Already Complete
- [x] `purchase_service.dart` created with all purchase logic
- [x] `in_app_purchase` package in pubspec.yaml
- [x] Settings model has `isPro` field
- [x] Pro screen displays pricing ($3.99, $23.99, $39.99)
- [x] All Pro features check `settings.isPro` before showing content

### ⏳ Needs Implementation (Code Changes)

## Phase 1: Wire Up Purchase Buttons (30 minutes)

### File: `lib/features/pro/pro_screen.dart`

**What to change**: The button `onPressed` callbacks (line ~670)

**Current Code**:
```dart
FilledButton(
  onPressed: () {
    // TODO: Implement actual purchase flow with in_app_purchase
    // For now, buttons are visible but purchase implementation pending
  },
  child: Text(recommended ? 'Start Free Trial' : 'Choose Plan'),
)
```

**New Code**:
```dart
FilledButton(
  onPressed: () => _handlePurchase(context, ref, productId),
  child: Text(recommended ? 'Start Free Trial' : 'Choose Plan'),
)
```

**Add this method to ProScreen**:
```dart
Future<void> _handlePurchase(
  BuildContext context,
  WidgetRef ref,
  String productId,
) async {
  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Load products from Google Play
    final purchaseService = ref.read(purchaseServiceProvider);
    final products = await purchaseService.loadProducts();

    // Find the product
    final product = products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    // Close loading
    if (context.mounted) Navigator.pop(context);

    // Initiate purchase (Google Play handles the UI)
    final success = await purchaseService.purchaseProduct(product);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase cancelled or failed'),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Update the pricing cards** to pass product IDs:
```dart
// Monthly card (line ~490)
_buildPricingCard(
  context,
  title: 'Pro Monthly',
  price: '\$3.99',
  period: 'per month',
  productId: 'pro_monthly', // ADD THIS
  features: [...],
  recommended: false,
),

// Annual card (line ~530)
_buildPricingCard(
  context,
  title: 'Annual',
  price: '\$23.99',
  period: 'per year',
  productId: 'pro_annual', // ADD THIS
  badge: 'BEST VALUE',
  features: [...],
  recommended: true,
),

// Lifetime card (line ~570)
_buildPricingCard(
  context,
  title: 'Founder Lifetime',
  price: '\$39.99',
  period: 'one time',
  productId: 'founder_lifetime', // ADD THIS
  badge: 'LIMITED',
  features: [...],
  recommended: false,
  isFounder: true,
),
```

**Update `_buildPricingCard` signature**:
```dart
Widget _buildPricingCard(
  BuildContext context, {
  required String title,
  required String price,
  required String period,
  required String productId, // ADD THIS
  required List<String> features,
  String? badge,
  bool recommended = false,
  bool isFounder = false,
}) {
  // ... existing code ...
  
  // In the button:
  FilledButton(
    onPressed: () => _handlePurchase(context, ref, productId),
    child: Text(recommended ? 'Start Free Trial' : 'Choose Plan'),
  )
}
```

**Add import**:
```dart
import '../../services/purchase_service.dart';
```

---

## Phase 2: Initialize Purchase Service (5 minutes)

### File: `lib/app.dart`

**What to change**: The `appInitProvider` (line 66)

**Add to initialization**:
```dart
final appInitProvider = FutureProvider<bool>((ref) async {
  try {
    // Initialize Hive and repositories
    await RepositoryService.initialize();
    
    // Initialize purchase service
    final purchaseService = ref.read(purchaseServiceProvider);
    await purchaseService.initialize(ref);
    
    return true;
  } catch (e) {
    // ... existing error handling ...
  }
});
```

---

## Phase 3: Add Restore Purchases Button (10 minutes)

### File: `lib/features/pro/pro_screen.dart`

**Where**: In the `_buildUpgradeScreen` method, after the pricing cards

**Add this button**:
```dart
const SizedBox(height: 24),
Center(
  child: TextButton.icon(
    onPressed: () => _restorePurchases(context, ref),
    icon: const Icon(Icons.restore),
    label: const Text('Restore Purchases'),
  ),
),
```

**Add this method**:
```dart
Future<void> _restorePurchases(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Restoring purchases...'),
          ],
        ),
      ),
    );

    // Restore purchases
    final purchaseService = ref.read(purchaseServiceProvider);
    await purchaseService.restorePurchases(ref);

    if (context.mounted) {
      Navigator.pop(context); // Close loading
      
      // Check if Pro was restored
      final settings = ref.read(settingsProvider).value;
      if (settings?.isPro ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Purchases restored! Pro access activated.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchases found.'),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

## Phase 4: Google Play Console Setup (Outside Code)

See `docs/GOOGLE_PLAY_IAP_SETUP.md` for complete guide.

**Key Steps**:
1. Create app in Google Play Console
2. Upload APK to Internal Testing track
3. Create 3 products:
   - `pro_monthly` - $3.99/month subscription
   - `pro_annual` - $23.99/year subscription
   - `founder_lifetime` - $39.99 one-time purchase
4. Add yourself as License Tester
5. Wait 2-4 hours for products to sync

---

## What Happens When User Purchases?

### Flow Diagram:
```
User taps "Start Free Trial"
  ↓
_handlePurchase() loads products
  ↓
Calls purchaseService.purchaseProduct()
  ↓
Google Play payment dialog appears
  ↓
User completes purchase
  ↓
purchaseStream receives update
  ↓
_handlePurchaseUpdates() called
  ↓
_verifyPurchase() checks validity
  ↓
_grantProAccess() sets isPro = true
  ↓
Settings saved to Hive
  ↓
settingsProvider updates
  ↓
UI rebuilds → Pro features unlocked! 🎉
```

---

## Testing Checklist

### Before Testing
- [ ] App uploaded to Internal Testing track in Play Console
- [ ] Products created and activated in Play Console
- [ ] Your email added to License Testers
- [ ] Waited 2-4 hours for sync
- [ ] Installed app from Google Play (NOT sideload)

### Test Cases
- [ ] Tap "Start Free Trial" (monthly) → Google Play dialog appears
- [ ] Complete "purchase" (no charge for testers)
- [ ] Pro features unlock immediately
- [ ] Restart app → Pro status persists
- [ ] Clear app data → Tap "Restore Purchases" → Pro restored
- [ ] Try annual plan → Works
- [ ] Try lifetime plan → Works
- [ ] Cancel during payment → Gracefully handles

---

## Common Issues & Solutions

### "Product not found"
- **Cause**: Products not synced yet
- **Solution**: Wait 2-4 hours after creating products

### "In-app purchases not available"
- **Cause**: Not installed from Play Store
- **Solution**: Install from Internal Testing link

### Purchase doesn't unlock Pro
- **Cause**: `_grantProAccess()` not being called
- **Solution**: Check console logs for errors, verify purchaseStream listener

### Can't test without being charged
- **Cause**: Not added to License Testers
- **Solution**: Add your Gmail to License Testing in Play Console

---

## Estimated Implementation Time

- **Phase 1** (Wire buttons): 30 minutes
- **Phase 2** (Initialize): 5 minutes  
- **Phase 3** (Restore): 10 minutes
- **Phase 4** (Console setup): 30 minutes
- **Testing**: 2-3 hours (with waiting for sync)

**Total**: ~4 hours

---

## After Implementation

Once coded and tested, you can:
1. ✅ Users can purchase Pro subscriptions
2. ✅ Free trials work (7 days)
3. ✅ Purchases restore on reinstall
4. ✅ Revenue shows in Play Console
5. ✅ 85% of revenue goes to you (15% to Google)

## Important Notes

- **Subscriptions auto-renew** - Google handles billing
- **Grace period** - 3 days after failed payment before cancellation
- **Refunds** - You can issue in Play Console (within 48 hours)
- **Founder Lifetime** - One-time purchase, no recurring billing
- **First 1,000** - You'll need to manually track in Play Console or add counter

Good luck with launch! 🚀
