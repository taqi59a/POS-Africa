import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sales_bloc.dart';
import '../../../inventory/presentation/bloc/inventory_bloc.dart';
import '../../../customers/presentation/bloc/customer_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../widgets/product_selector.dart';
import '../widgets/cart_list.dart';
import '../widgets/sale_summary.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            tooltip: 'Hold Sale',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Cart',
            onPressed: () => context.read<SalesBloc>().add(ClearCart()),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Product Selection
          Expanded(
            flex: 3,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: const ProductSelector(),
            ),
          ),

          const VerticalDivider(width: 1),

          // Right Side: Customer bar + Cart + Summary
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // ── Customer Search Bar ──────────────────────────────────
                const _CustomerSearchBar(),
                const Divider(height: 1),
                const Expanded(child: CartList()),
                const Divider(height: 1),
                const SaleSummary(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customer search autocomplete ───────────────────────────────────────────
class _CustomerSearchBar extends StatefulWidget {
  const _CustomerSearchBar();
  @override
  State<_CustomerSearchBar> createState() => _CustomerSearchBarState();
}

class _CustomerSearchBarState extends State<_CustomerSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesState = context.watch<SalesBloc>().state;
    final selected = salesState.selectedCustomer;

    if (selected != null) {
      // Show chip for selected customer
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
        child: Row(
          children: [
            const Icon(Icons.person_rounded, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if ((selected.balanceOwed) > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Owes: CDF ${selected.balanceOwed.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: Colors.red[700]),
                ),
              ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                context.read<SalesBloc>().add(const SetSelectedCustomer(null));
                _controller.clear();
              },
              child: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      );
    }

    // Show autocomplete search
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (ctx, customerState) {
        final customers = customerState is CustomerLoaded ? customerState.customers : <Customer>[];
        return Autocomplete<Customer>(
          optionsBuilder: (textValue) {
            if (textValue.text.isEmpty) return customers.take(5);
            final q = textValue.text.toLowerCase();
            return customers.where((c) =>
                c.fullName.toLowerCase().contains(q) ||
                (c.phone?.contains(q) ?? false));
          },
          displayStringForOption: (c) => c.fullName,
          fieldViewBuilder: (ctx2, fieldCtrl, focusNode, onEditingComplete) {
            return TextField(
              controller: fieldCtrl,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Search customer (or leave empty for walk-in)…',
                prefixIcon: const Icon(Icons.person_search_rounded, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: false,
                suffixIcon: fieldCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => fieldCtrl.clear(),
                      )
                    : null,
              ),
            );
          },
          onSelected: (customer) {
            context.read<SalesBloc>().add(SetSelectedCustomer(customer));
          },
          optionsViewBuilder: (ctx2, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final c = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text(c.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 12)),
                        ),
                        title: Text(c.fullName),
                        subtitle: c.phone != null ? Text(c.phone!) : null,
                        trailing: c.balanceOwed > 0
                            ? Text('Owes: CDF ${c.balanceOwed.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.red, fontSize: 11))
                            : null,
                        onTap: () => onSelected(c),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
