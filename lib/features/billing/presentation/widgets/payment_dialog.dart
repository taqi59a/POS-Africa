import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' hide Column;
import '../bloc/sales_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'receipt_dialog.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final TextEditingController _cdfController = TextEditingController();
  final TextEditingController _usdController = TextEditingController();
  final TextEditingController _chargeController = TextEditingController();

  String _paymentMethod = 'CASH';
  double _amountTenderedCdf = 0;
  double? _customCharge;        // null = use cart total
  bool   _chargeInitialized = false; // seed controller once on first build

  @override
  void dispose() {
    _cdfController.dispose();
    _usdController.dispose();
    _chargeController.dispose();
    super.dispose();
  }

  double _calcVat(Map<String, String> settings, double grandTotal) {
    final vatEnabled = (settings['vat_enabled'] ?? 'false') == 'true';
    if (!vatEnabled) return 0.0;
    final vatPct = double.tryParse(settings['vat_percentage'] ?? '16') ?? 16;
    final vatMode = settings['vat_mode'] ?? 'inclusive';
    if (vatMode == 'inclusive') {
      return grandTotal * vatPct / (100 + vatPct);
    } else {
      return grandTotal * vatPct / 100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final settings = settingsState is SettingsLoaded ? settingsState.settings : <String, String>{};
        final exchangeRate = double.tryParse(settings['usd_exchange_rate'] ?? '2850') ?? 2850;
        final dualCurrency = (settings['dual_currency_enabled'] ?? 'false') == 'true';

        return BlocConsumer<SalesBloc, SalesState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.error}'), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state.lastSaleReceipt != null) {
              return ReceiptDialog(receipt: state.lastSaleReceipt!);
            }

            final grandTotalCdf = state.grandTotal;

            // Seed the editable bill-total field once when the dialog first opens.
            if (!_chargeInitialized) {
              _chargeInitialized = true;
              _chargeController.text = grandTotalCdf.toStringAsFixed(0);
            }

            // effectiveCharge: whatever the cashier typed in the bill field.
            // Defaults to cart total; can be set higher for elevated pricing.
            final effectiveCharge = (_customCharge != null && _customCharge! > 0)
                ? _customCharge!
                : grandTotalCdf;
            final grandTotalUsd = effectiveCharge / exchangeRate;
            final vatAmount = _calcVat(settings, effectiveCharge);
            final selectedCustomer = state.selectedCustomer;
            final isWalkIn = selectedCustomer == null;

            // Walk-in customers always pay cash — force method back if needed
            if (isWalkIn && _paymentMethod != 'CASH') {
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => setState(() => _paymentMethod = 'CASH'));
            }

            final isCredit = _paymentMethod == 'CREDIT';
            final effectiveTendered = isCredit ? effectiveCharge : _amountTenderedCdf;
            final changeDue = isCredit ? 0.0 : (effectiveTendered - effectiveCharge).clamp(0.0, double.infinity);
            final canComplete = !state.isProcessing &&
                (isCredit || effectiveTendered >= effectiveCharge);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 520,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────
                    Text('Payment',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),

                    // ── Customer chip or Walk-in badge ──────
                    if (selectedCustomer != null) ...[
                      const SizedBox(height: 8),
                      Chip(
                        avatar: const Icon(Icons.person_rounded, size: 16),
                        label: Text(selectedCustomer.fullName),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer.withAlpha(120),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueGrey.withAlpha(60)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 6),
                          const Text('Walk-in Customer — Cash Payment',
                              style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Bill Total (directly editable) ──────────────────
                    // The cashier can tap the amount and type a different
                    // value (e.g. elevated price for a specific customer).
                    // The difference goes to revenue, not change.
                    // On the next sale the field resets to the new cart total.
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withAlpha(77),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('BILL TOTAL',
                                  style: TextStyle(
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12)),
                              if (effectiveCharge != grandTotalCdf)
                                Text(
                                  'Cart: FC ${grandTotalCdf.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.orange),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _chargeController,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: effectiveCharge != grandTotalCdf
                                  ? Colors.orange.shade800
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixText: 'FC ',
                              prefixStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: effectiveCharge != grandTotalCdf
                                    ? Colors.orange.shade700
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              hintText: grandTotalCdf.toStringAsFixed(0),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final parsed = double.tryParse(val);
                              setState(() {
                                _customCharge =
                                    (parsed != null && parsed > 0) ? parsed : null;
                              });
                            },
                          ),
                          if (dualCurrency)
                            Text(
                              '(\$${grandTotalUsd.toStringAsFixed(2)})',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          if (vatAmount > 0)
                            Text(
                              'Incl. VAT: FC ${vatAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          if (effectiveCharge != grandTotalCdf)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Markup: +FC ${(effectiveCharge - grandTotalCdf).abs().toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Tap the amount above to change the bill total',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Payment Method (customers only — walk-in auto-cash) ──
                    if (!isWalkIn) ...[
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: const InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(
                              value: 'CASH', child: Text('Cash')),
                          const DropdownMenuItem(
                              value: 'MOBILE_MONEY',
                              child: Text('Mobile Money')),
                          const DropdownMenuItem(
                              value: 'CREDIT', child: Text('Credit (on account)')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _paymentMethod = val!;
                            if (val != 'CREDIT') _amountTenderedCdf = 0;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Tendered amount (hidden for credit) ─
                    if (!isCredit) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cdfController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                labelText: 'Amount Tendered (FC)',
                                border: OutlineInputBorder(),
                                prefixText: 'FC ',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final amount = double.tryParse(val) ?? 0;
                                if (dualCurrency) {
                                  _usdController.text =
                                      (amount / exchangeRate).toStringAsFixed(2);
                                }
                                setState(() => _amountTenderedCdf = amount);
                              },
                            ),
                          ),
                          if (dualCurrency) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _usdController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount Tendered (USD)',
                                  border: OutlineInputBorder(),
                                  prefixText: '\$ ',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  final amountUsd = double.tryParse(val) ?? 0;
                                  final amountCdf = amountUsd * exchangeRate;
                                  _cdfController.text =
                                      amountCdf.toStringAsFixed(0);
                                  setState(
                                      () => _amountTenderedCdf = amountCdf);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      // Credit info card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Full amount FC ${effectiveCharge.toStringAsFixed(0)} will be added to ${selectedCustomer?.fullName ?? ""}\u0027s account.',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Change due ──────────────────
                    if (!isCredit && changeDue > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('CHANGE DUE',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                            Text(
                              'FC ${changeDue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ── Action buttons ──────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.isProcessing
                                ? null
                                : () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('CANCEL'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canComplete
                                ? () {
                                    final authState =
                                        context.read<AuthBloc>().state;
                                    final cashierId =
                                        authState is AuthAuthenticated
                                            ? authState.user.id
                                            : 1;
                                    context.read<SalesBloc>().add(CompleteSale(
                                          cashierId: cashierId,
                                          customerId: selectedCustomer?.id,
                                          exchangeRate: exchangeRate,
                                          grandTotalUsd: grandTotalUsd,
                                          vatAmount: vatAmount,
                                          overrideGrandTotal:
                                              (_customCharge != null && _customCharge != grandTotalCdf)
                                                  ? _customCharge
                                                  : null,
                                          payments: [
                                            PaymentsCompanion.insert(
                                              saleId: 0,
                                              method: _paymentMethod,
                                              amountPaid: effectiveCharge,
                                              amountTendered:
                                                  Value(effectiveTendered),
                                              changeDue: Value(changeDue),
                                            )
                                          ],
                                        ));
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: state.isProcessing
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('COMPLETE SALE',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
