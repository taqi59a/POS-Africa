import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/report_bloc.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    context.read<ReportBloc>().add(LoadDailySalesSummary(_selectedDate));
    context.read<ReportBloc>().add(LoadInventoryValuation());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _refresh();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Sales Summary', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildSalesCards(state),
                const SizedBox(height: 48),
                Text('Inventory Status', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildInventoryCard(state),
                const SizedBox(height: 48),
                // TODO: Add Top Selling Products chart/list
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesCards(ReportState state) {
    if (state is! ReportDataState) return const LinearProgressIndicator();
    if (state.isLoadingDaily) return const LinearProgressIndicator();
    if (state.error != null) return Text('Error: ${state.error}', style: const TextStyle(color: Colors.red));
    final s = state.dailySummary;
    if (s == null) return const SizedBox();
    return Row(
      children: [
        _ReportCard(label: 'Transactions', value: s['count']?.toStringAsFixed(0) ?? '0', icon: Icons.receipt),
        const SizedBox(width: 16),
        _ReportCard(label: 'Total Revenue', value: 'CDF ${s['total']?.toStringAsFixed(0) ?? '0'}', icon: Icons.payments, color: Colors.green),
        const SizedBox(width: 16),
        _ReportCard(label: 'Total Discounts', value: 'CDF ${s['discount']?.toStringAsFixed(0) ?? '0'}', icon: Icons.local_offer, color: Colors.orange),
      ],
    );
  }

  Widget _buildInventoryCard(ReportState state) {
    if (state is! ReportDataState) return const SizedBox();
    if (state.isLoadingInventory) return const LinearProgressIndicator();
    final total = state.inventoryValuation;
    if (total == null) return const SizedBox();
    return Row(
      children: [
        _ReportCard(
          label: 'Total Inventory Value (Cost)',
          value: 'CDF ${total.toStringAsFixed(0)}',
          icon: Icons.inventory,
          color: Colors.blue,
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _ReportCard({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color ?? Theme.of(context).colorScheme.primary, size: 32),
              const SizedBox(height: 16),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
