import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' hide Column;
import '../bloc/sales_bloc.dart';
import '../../settings/presentation/bloc/settings_bloc.dart';
import '../../../../core/data/database/app_database.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final TextEditingController _cdfController = TextEditingController();
  final TextEditingController _usdController = TextEditingController();
  
  String _paymentMethod = 'CASH';
  double _amountTenderedCdf = 0;
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final settings = settingsState is SettingsLoaded ? settingsState.settings : <String, String>{};
        final exchangeRate = double.tryParse(settings['usd_exchange_rate'] ?? '2850') ?? 2850;

        return BlocConsumer<SalesBloc, SalesState>(
          listener: (context, state) {
            if (state.lastCompletedSaleId != null) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sale #${state.lastCompletedSaleId} completed successfully!')),
              );
              // TODO: Open Receipt Preview/Print
            }
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.error}'), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            final grandTotalCdf = state.grandTotal;
            final grandTotalUsd = grandTotalCdf / exchangeRate;
            final changeDue = _amountTenderedCdf - grandTotalCdf;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Payment', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    
                    // Total display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('AMOUNT TO PAY', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w500)),
                          Text(
                            'CDF ${grandTotalCdf.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '(\$${grandTotalUsd.toStringAsFixed(2)})',
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment Method
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                        DropdownMenuItem(value: 'MOBILE_MONEY', child: Text('Mobile Money')),
                        DropdownMenuItem(value: 'CREDIT', child: Text('Credit')),
                      ],
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Input Section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cdfController,
                            decoration: const InputDecoration(
                              labelText: 'Pay in CDF',
                              border: OutlineInputBorder(),
                              prefixText: 'CDF ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final amount = double.tryParse(val) ?? 0;
                              _usdController.text = (amount / exchangeRate).toStringAsFixed(2);
                              setState(() => _amountTenderedCdf = amount);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _usdController,
                            decoration: const InputDecoration(
                              labelText: 'Pay in USD',
                              border: OutlineInputBorder(),
                              prefixText: '\$ ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final amountUsd = double.tryParse(val) ?? 0;
                              final amountCdf = amountUsd * exchangeRate;
                              _cdfController.text = amountCdf.toStringAsFixed(0);
                              setState(() => _amountTenderedCdf = amountCdf);
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Change display
                    if (changeDue > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('CHANGE DUE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            Text(
                              'CDF ${changeDue.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.isProcessing ? null : () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('CANCEL'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: state.isProcessing || _amountTenderedCdf < grandTotalCdf
                                ? null
                                : () {
                                    context.read<SalesBloc>().add(CompleteSale(
                                          cashierId: 1, // TODO: Get logged in user ID
                                          exchangeRate: exchangeRate,
                                          grandTotalUsd: grandTotalUsd,
                                          payments: [
                                            PaymentsCompanion.insert(
                                              saleId: const Value(0),
                                              method: _paymentMethod,
                                              amountPaid: grandTotalCdf,
                                              amountTendered: Value(_amountTenderedCdf),
                                              changeDue: Value(changeDue),
                                            )
                                          ],
                                        ));
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: state.isProcessing
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('COMPLETE SALE (Enter)', style: TextStyle(fontWeight: FontWeight.bold)),
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
