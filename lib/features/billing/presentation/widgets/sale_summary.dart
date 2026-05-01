import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sales_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'payment_dialog.dart';

class SaleSummary extends StatelessWidget {
  const SaleSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final settings = settingsState is SettingsLoaded ? settingsState.settings : <String, String>{};
        final exchangeRate = double.tryParse(settings['usd_exchange_rate'] ?? '2850') ?? 2850;
        final dualCurrency = (settings['dual_currency_enabled'] ?? 'false') == 'true';

        return BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) {
            final grandTotalUsd = state.grandTotal / exchangeRate;

            return Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Subtotal', value: 'FC ${state.subtotal.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Discount',
                    value: '- FC ${state.totalDiscount.toStringAsFixed(0)}',
                    valueColor: Colors.red,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'FC ${state.grandTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          if (dualCurrency)
                            Text(
                              'USD \$${grandTotalUsd.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: state.cart.isEmpty
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(value: context.read<SalesBloc>()),
                                    BlocProvider.value(value: context.read<SettingsBloc>()),
                                    BlocProvider.value(value: context.read<AuthBloc>()),
                                  ],
                                  child: const PaymentDialog(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('PAYMENT (F12)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
