import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../reports/presentation/bloc/report_bloc.dart';
import '../../inventory/presentation/bloc/inventory_bloc.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportBloc>().add(LoadDailySalesSummary(DateTime.now()));
    context.read<InventoryBloc>().add(LoadLowStockProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            BlocBuilder<ReportBloc, ReportState>(
              builder: (context, state) {
                final data = state is ReportDataState ? state : null;
                final sales = data?.dailySummary?['total'] ?? 0.0;
                final trxCount = data?.dailySummary?['count'] ?? 0.0;

                return Row(
                  children: [
                    _StatCard(
                      label: "Today's Sales",
                      value: 'CDF ${sales.toStringAsFixed(0)}',
                      icon: Icons.auto_graph,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 24),
                    _StatCard(
                      label: "Transactions",
                      value: trxCount.toStringAsFixed(0),
                      icon: Icons.receipt_long,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 24),
                    BlocBuilder<InventoryBloc, InventoryState>(
                      builder: (context, invState) {
                        final lowStock = invState is InventoryLoaded ? invState.products.length : 0;
                        return _StatCard(
                          label: "Low Stock Items",
                          value: lowStock.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: lowStock > 0 ? Colors.red : Colors.green,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
              _QuickAction(
                  label: 'New Sale',
                  icon: Icons.add_shopping_cart,
                  onTap: () => widget.onNavigate?.call(1),
                ),
                _QuickAction(
                  label: 'Add Product',
                  icon: Icons.add_box,
                  onTap: () => widget.onNavigate?.call(2),
                ),
                _QuickAction(
                  label: 'New Expense',
                  icon: Icons.money_off,
                  onTap: () => widget.onNavigate?.call(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 24),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
