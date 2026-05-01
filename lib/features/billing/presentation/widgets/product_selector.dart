import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../inventory/presentation/bloc/inventory_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../bloc/sales_bloc.dart';
import '../../../../core/data/database/app_database.dart';

class ProductSelector extends StatefulWidget {
  const ProductSelector({super.key});

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Barcode scanner support — USB scanners type fast + Enter
  final _barcodeBuffer = StringBuffer();
  DateTime? _lastKeyTime;
  static const _barcodeMaxGapMs = 80; // chars within 80ms = scanner input

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(LoadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String value, List<Product> products) {
    if (value.trim().isEmpty) return;
    // Try exact barcode match first
    final byBarcode = products.where((p) =>
        p.isActive &&
        p.barcode != null &&
        p.barcode!.toLowerCase() == value.trim().toLowerCase()).toList();
    if (byBarcode.length == 1) {
      context.read<SalesBloc>().add(AddProductToCart(byBarcode.first));
      _searchController.clear();
      context.read<InventoryBloc>().add(LoadProducts());
      _showScannedItem(byBarcode.first);
      return;
    }
    // Try exact SKU match
    final bySku = products.where((p) =>
        p.isActive &&
        p.sku != null &&
        p.sku!.toLowerCase() == value.trim().toLowerCase()).toList();
    if (bySku.length == 1) {
      context.read<SalesBloc>().add(AddProductToCart(bySku.first));
      _searchController.clear();
      context.read<InventoryBloc>().add(LoadProducts());
      _showScannedItem(bySku.first);
      return;
    }
    // If only one result visible after search, auto-add it
    final filtered = products.where((p) =>
        p.isActive &&
        p.name.toLowerCase().contains(value.toLowerCase())).toList();
    if (filtered.length == 1) {
      context.read<SalesBloc>().add(AddProductToCart(filtered.first));
      _searchController.clear();
      context.read<InventoryBloc>().add(LoadProducts());
    }
  }

  void _showScannedItem(Product p) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.barcode_reader, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('Added: ${p.name} (×1)'),
      ]),
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        final products = state is InventoryLoaded ? state.products : <Product>[];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Scan barcode or search name...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Barcode scanner ready — just scan or type barcode + Enter',
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: Theme.of(context).colorScheme.primary.withAlpha(180),
                          size: 22,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<InventoryBloc>().add(LoadProducts());
                          },
                        ),
                    ],
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (query) {
                  setState(() {});
                  context.read<InventoryBloc>().add(SearchProducts(query));
                },
                onSubmitted: (val) => _onSearchSubmitted(val, products),
                textInputAction: TextInputAction.search,
              ),
            ),
            Expanded(
              child: state is InventoryLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state is InventoryLoaded
                      ? _buildGrid(context, products)
                      : const SizedBox(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<Product> allProducts) {
    final products = allProducts.where((p) => p.isActive).toList();
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
                              'FC ${product.sellingPrice.toStringAsFixed(0)}',
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
}
