import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app.dart';
import '../../../data/models.dart';
import '../../../data/repositories.dart';
import '../../../generated/app_localizations.dart';
import '../../../routes.dart' show AppRouter;

class ExpandableDueSoonCard extends StatefulWidget {
  final List<Liability> liabilities;
  final WidgetRef ref;

  const ExpandableDueSoonCard({
    super.key,
    required this.liabilities,
    required this.ref,
  });

  @override
  State<ExpandableDueSoonCard> createState() => _ExpandableDueSoonCardState();
}

class _ExpandableDueSoonCardState extends State<ExpandableDueSoonCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryLiability = widget.liabilities.first;
    final totalLiabilities = widget.liabilities.length;

    // Determine primary colors based on most urgent liability
    Color backgroundColor;
    Color textColor;
    Color severityColor;
    String statusText;
    IconData iconData;

    if (primaryLiability.isOverdue) {
      backgroundColor = Colors.red.withValues(alpha: 0.06);
      textColor = Colors.red.shade800;
      severityColor = Colors.red.shade600;
      statusText = 'Overdue';
      iconData = Icons.warning;
    } else if (primaryLiability.daysUntilDue == 0) {
      backgroundColor = Colors.red.withValues(alpha: 0.06);
      textColor = Colors.red.shade800;
      severityColor = Colors.red.shade600;
      statusText = 'Due Today';
      iconData = Icons.today;
    } else {
      backgroundColor = Colors.orange.withValues(alpha: 0.06);
      textColor = Colors.orange.shade800;
      severityColor = Colors.orange.shade600;
      statusText = 'Due Soon';
      iconData = Icons.calendar_today;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with severity chip, title, timestamp and chevron
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                // Severity chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Icon
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    iconData,
                    color: textColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Due',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$totalLiabilities ${totalLiabilities == 1 ? 'liability' : 'liabilities'} need attention',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expand/collapse chevron
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isExpanded ? 0.5 : 0,
                  child: Icon(
                    Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Expandable content section
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      // All liabilities
                      ...widget.liabilities.asMap().entries.map((entry) {
                        final index = entry.key;
                        final liability = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index < widget.liabilities.length - 1 ? 12 : 0,
                          ),
                          child: _buildLiabilityRow(
                            liability,
                            isFirst: index == 0,
                          ),
                        );
                      }),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilityRow(Liability liability, {required bool isFirst}) {
    final daysUntil = liability.daysUntilDue;

    // Determine colors and status for this specific liability
    Color textColor;
    Color pillColor;
    String statusText;

    if (liability.isOverdue) {
      textColor = Colors.red.shade800;
      pillColor = Colors.red.shade600;
      statusText = 'Overdue';
    } else if (daysUntil == 0) {
      textColor = Colors.red.shade800;
      pillColor = Colors.red.shade600;
      statusText = 'Due Today';
    } else if (daysUntil == 1) {
      textColor = Colors.orange.shade800;
      pillColor = Colors.orange.shade600;
      statusText = 'Due Tomorrow';
    } else {
      textColor = Colors.orange.shade800;
      pillColor = Colors.orange.shade600;
      statusText = 'Due Soon';
    }

    // Format due date text
    String dueDateText;
    if (liability.isOverdue) {
      final overdueDays = -daysUntil!;
      dueDateText = overdueDays == 1
          ? '${liability.name} overdue by 1 day — '
          : '${liability.name} overdue by $overdueDays days — ';
    } else if (daysUntil == 0) {
      dueDateText = '${liability.name} due today — ';
    } else if (daysUntil == 1) {
      dueDateText = '${liability.name} due tomorrow — ';
    } else {
      dueDateText = '${liability.name} due in $daysUntil days — ';
    }

    return InkWell(
      onTap: () => context.push('${AppRouter.liabilities}/${liability.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                  children: [
                    TextSpan(
                      text: '$statusText • ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: dueDateText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text:
                          '\$${liability.minPayment.toStringAsFixed(0)} minimum',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Paid button
            InkWell(
              onTap: () => _showPaymentDialog(context, liability),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Paid',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Liability liability) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PaymentDialog(
        liability: liability,
        onPaymentComplete: () async {
          // Trigger dashboard data reload from the parent context
          await widget.ref.read(liabilitiesProvider.notifier).reload();
          await widget.ref.read(accountsProvider.notifier).reload();
          debugPrint('Dashboard providers reloaded after payment');
        },
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final Liability liability;
  final Future<void> Function() onPaymentComplete;

  const _PaymentDialog({
    required this.liability,
    required this.onPaymentComplete,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _amountController = TextEditingController();
  String _selectedPaymentType = 'minimum';
  double? _customAmount;
  String? _notes;

  @override
  void initState() {
    super.initState();
    _updateAmountForPaymentType();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateAmountForPaymentType() {
    double amount;
    switch (_selectedPaymentType) {
      case 'minimum':
        amount = widget.liability.minPayment;
        break;
      case 'full':
        amount = widget.liability.balance;
        break;
      case 'round_up':
        final roundUp =
            ((widget.liability.minPayment / 50).ceil() * 50).toDouble();
        amount = roundUp;
        break;
      case 'extra':
        amount = widget.liability.minPayment + 50;
        break;
      case 'custom':
        amount = _customAmount ?? widget.liability.minPayment;
        break;
      default:
        amount = widget.liability.minPayment;
    }

    _amountController.text = amount.toStringAsFixed(2);
  }

  double get _paymentAmount => double.tryParse(_amountController.text) ?? 0.0;
  double get _newBalance =>
      (widget.liability.balance - _paymentAmount).clamp(0.0, double.infinity);
  bool get _isValidPayment =>
      _paymentAmount > 0 && _paymentAmount <= widget.liability.balance;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.payment,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mark as Paid',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.liability.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Current balance info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Balance'),
                        Text(
                          '\$${widget.liability.balance.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context)!.minimumPayment),
                        Text(
                          '\$${widget.liability.minPayment.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment type selection
              const Text(
                'Payment Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPaymentTypeChip(
                    'minimum',
                    'Minimum',
                    '\$${widget.liability.minPayment.toStringAsFixed(0)}',
                  ),
                  _buildPaymentTypeChip(
                    'round_up',
                    'Round Up',
                    '\$${((widget.liability.minPayment / 50).ceil() * 50).toStringAsFixed(0)}',
                  ),
                  _buildPaymentTypeChip(
                    'extra',
                    'Extra \$50',
                    '\$${(widget.liability.minPayment + 50).toStringAsFixed(0)}',
                  ),
                  _buildPaymentTypeChip('full', 'Pay Off', 'Full'),
                  _buildPaymentTypeChip('custom', 'Custom', 'Custom'),
                ],
              ),
              const SizedBox(height: 16),

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: !_isValidPayment && _paymentAmount > 0
                      ? 'Amount cannot exceed balance'
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _customAmount = double.tryParse(value);
                    if (_selectedPaymentType != 'custom') {
                      _selectedPaymentType = 'custom';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Notes (optional)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add a note about this payment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
                onChanged: (value) {
                  _notes = value.isEmpty ? null : value;
                },
              ),
              const SizedBox(height: 20),

              // Payment preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Amount'),
                        Text(
                          '\$${_paymentAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New Balance'),
                        Text(
                          '\$${_newBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _isValidPayment ? () => _processPayment() : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Mark as Paid',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeChip(String type, String label, String amount) {
    final isSelected = _selectedPaymentType == type;
    return FilterChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
          if (type != 'custom')
            Text(
              amount,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPaymentType = type;
            _updateAmountForPaymentType();
          });
        }
      },
      selectedColor: Colors.green.shade600,
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Future<void> _processPayment() async {
    if (!_isValidPayment) return;

    try {
      // Create payment record
      final payment = Payment.create(
        liabilityId: widget.liability.id,
        amount: _paymentAmount,
        paymentType: _selectedPaymentType,
        notes: _notes,
        previousBalance: widget.liability.balance,
        newBalance: _newBalance,
      );

      // Save payment to database
      await RepositoryService.savePayment(payment);

      // Update liability balance and due date
      final updatedLiability = Liability(
        id: widget.liability.id,
        name: widget.liability.name,
        balance: _newBalance,
        minPayment: _newBalance == 0 ? 0 : widget.liability.minPayment,
        apr: widget.liability.apr,
        kind: widget.liability.kind,
        updatedAt: DateTime.now(),
        creditLimit: widget.liability.creditLimit,
        nextPaymentDate: _calculateNextPaymentDate(),
        paymentFrequencyDays: widget.liability.paymentFrequencyDays,
        dayOfMonth: widget.liability.dayOfMonth,
      );

      // Save updated liability
      await RepositoryService.saveLiability(updatedLiability);

      // Debug: Print the updated balance
      debugPrint(
        'Payment processed: ${widget.liability.name} balance updated from ${widget.liability.balance} to ${updatedLiability.balance}',
      );

      if (!mounted) return;

      // Close dialog first
      Navigator.pop(context);

      // Trigger dashboard data reload using callback
      await widget.onPaymentComplete();

      if (!mounted) return;

      // Show success message
      final message = _paymentAmount >= widget.liability.balance
          ? 'Congratulations! ${widget.liability.name} has been paid off!'
          : 'Payment of \$${_paymentAmount.toStringAsFixed(2)} recorded for ${widget.liability.name}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  DateTime? _calculateNextPaymentDate() {
    // If the liability is paid off, no next payment date
    if (_newBalance == 0) return null;

    final now = DateTime.now();
    final currentDueDate = widget.liability.nextPaymentDate;

    // If no current due date or frequency info, return null
    if (currentDueDate == null ||
        widget.liability.paymentFrequencyDays == null) {
      return null;
    }

    // Calculate next payment date based on frequency
    final frequency = widget.liability.paymentFrequencyDays!;

    // If current payment is overdue, calculate from today
    if (currentDueDate.isBefore(now)) {
      return DateTime(
        now.year,
        now.month + 1,
        widget.liability.dayOfMonth ?? 1,
      );
    }

    // Otherwise, advance by the frequency period
    return currentDueDate.add(Duration(days: frequency));
  }
}
