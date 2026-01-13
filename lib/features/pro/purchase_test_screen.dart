import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/purchase_service.dart';
import '../../app.dart';

/// Developer screen for testing in-app purchases
/// Access via: Settings -> Developer Options -> Test Purchases
class PurchaseTestScreen extends ConsumerStatefulWidget {
  const PurchaseTestScreen({super.key});

  @override
  ConsumerState<PurchaseTestScreen> createState() => _PurchaseTestScreenState();
}

class _PurchaseTestScreenState extends ConsumerState<PurchaseTestScreen> {
  List<ProductDetails>? _products;
  bool _loading = true;
  String? _error;
  bool _isAvailable = false;
  String _status = 'Checking...';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final purchaseService = ref.read(purchaseServiceProvider);

      // Check if IAP is available
      _isAvailable = await purchaseService.isAvailable();

      if (!_isAvailable) {
        setState(() {
          _status = 'In-app purchases NOT available on this device';
          _loading = false;
        });
        return;
      }

      setState(() {
        _status = 'In-app purchases available ✓';
      });

      // Load products
      final products = await purchaseService.loadProducts();

      setState(() {
        _products = products;
        _loading = false;
      });

      debugPrint('Loaded ${products.length} products from Play Store');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      debugPrint('Error loading purchase data: $e');
    }
  }

  Future<void> _testPurchase(ProductDetails product) async {
    try {
      final purchaseService = ref.read(purchaseServiceProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Initiating test purchase: ${product.title}'),
          duration: const Duration(seconds: 2),
        ),
      );

      final success = await purchaseService.purchaseProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✓ Purchase initiated successfully'
                  : '✗ Purchase failed or cancelled',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() {
        _status = 'Restoring purchases...';
      });

      final purchaseService = ref.read(purchaseServiceProvider);
      await purchaseService.restorePurchases();

      if (mounted) {
        setState(() {
          _status = 'Restore complete';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Restore purchases completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Restore failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final isPro = settingsAsync.value?.isPro ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Testing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Reload',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    color: _isAvailable
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isAvailable ? Icons.check_circle : Icons.error,
                                color: _isAvailable ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'IAP Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_status),
                          const SizedBox(height: 4),
                          Text(
                            'Pro Status: ${isPro ? "✓ ACTIVE" : "✗ Not Active"}',
                            style: TextStyle(
                              color: isPro ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Error display
                  if (_error != null) ...[
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(_error!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Product IDs Card
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product IDs in App',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Monthly: ${PurchaseService.monthlySubId}'),
                          Text('Annual: ${PurchaseService.annualSubId}'),
                          Text('Lifetime: ${PurchaseService.lifetimeId}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Available Products
                  const Text(
                    'Available Products from Google Play',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_products == null || _products!.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _products == null
                              ? 'Loading products...'
                              : 'No products found. Make sure products are created in Google Play Console.',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    )
                  else
                    ..._products!.map(
                      (product) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      product.price,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.description,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('ID: ${product.id}'),
                              Text('Raw Price: ${product.rawPrice}'),
                              Text('Currency: ${product.currencyCode}'),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _testPurchase(product),
                                  child: const Text('Test Purchase'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Restore Purchases Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _restorePurchases,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore Purchases'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Developer Notes
                  Card(
                    color: Colors.blue.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Testing Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Test with a real device (not emulator)',
                          ),
                          Text(
                            '• Use a test account added in Play Console',
                          ),
                          Text(
                            '• Test purchases are free but show real flow',
                          ),
                          Text(
                            '• Products must be published (at least to closed testing)',
                          ),
                          SizedBox(height: 8),
                          Text(
                            'If products don\'t load:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('1. Check product IDs match Play Console'),
                          Text('2. Ensure products are active'),
                          Text('3. Wait 24h after creating products'),
                          Text('4. Check device has Play Store access'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
