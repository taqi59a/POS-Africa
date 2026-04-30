import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../inventory/presentation/bloc/inventory_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../bloc/sales_bloc.dart';

class ProductSelector extends StatefulWidget {
  const ProductSelector({super.key});

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(LoadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Scan barcode or search name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (query) {
              context.read<InventoryBloc>().add(SearchProducts(query));
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<InventoryBloc, InventoryState>(
            builder: (context, state) {
              if (state is InventoryLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is InventoryLoaded) {
                final products = state.products.where((p) => p.isActive).toList();
                
                if (products.isEmpty) {
                  return const Center(child: Text('No active products found.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          context.read<SalesBloc>().add(AddProductToCart(product));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: const Icon(Icons.inventory_2, size: 48),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Builder(builder: (ctx) {
                                      final s = ctx.watch<SettingsBloc>().state;
                                      final cfg = s is SettingsLoaded ? s.settings : <String, String>{};
                                      final dual = (cfg['dual_currency_enabled'] ?? 'false') == 'true';
                                      final rate = double.tryParse(cfg['usd_exchange_rate'] ?? '2850') ?? 2850;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'CDF ${product.sellingPrice.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Theme.of(ctx).colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (dual)
                                            Text(
                                              '\$${(product.sellingPrice / rate).toStringAsFixed(2)}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                        ],
                                      );
                                    }),
                                  Text(
                                    'Stock: ${product.stockQuantity.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}
