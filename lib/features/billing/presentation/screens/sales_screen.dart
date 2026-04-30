import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sales_bloc.dart';
import '../../inventory/presentation/bloc/inventory_bloc.dart';
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
            onPressed: () {
              // TODO: Implement park sale
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Cart',
            onPressed: () {
              context.read<SalesBloc>().add(ClearCart());
            },
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

          // Right Side: Cart and Summary
          Expanded(
            flex: 2,
            child: Column(
              children: [
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
