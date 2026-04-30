import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../bloc/inventory_bloc.dart';
import 'add_edit_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  bool _showLowStockOnly = false;

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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          FilterChip(
            label: const Text('Low Stock'),
            selected: _showLowStockOnly,
            onSelected: (val) {
              setState(() => _showLowStockOnly = val);
              if (val) {
                context.read<InventoryBloc>().add(LoadLowStockProducts());
              } else {
                context.read<InventoryBloc>().add(LoadProducts());
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<InventoryBloc>().add(LoadProducts()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BlocProvider.value(
            value: context.read<InventoryBloc>(),
            child: const AddEditProductScreen(),
          )),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, barcode or SKU...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<InventoryBloc>().add(LoadProducts());
                        })
                    : null,
              ),
              onChanged: (q) => context.read<InventoryBloc>().add(SearchProducts(q)),
            ),
          ),
          // Content
          Expanded(
            child: BlocConsumer<InventoryBloc, InventoryState>(
              listener: (ctx, state) {
                if (state is InventoryError) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.red));
                }
                if (state is InventoryActionSuccess) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(state.message)));
                }
              },
              builder: (ctx, state) {
                if (state is InventoryLoading || state is InventoryInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is InventoryLoaded) {
                  if (state.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.outlineVariant),
                          const SizedBox(height: 16),
                          Text('No products found', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    );
                  }
                  return _ProductTable(products: state.products, categories: state.categories);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTable extends StatelessWidget {
  final List<Product> products;
  final List<Category> categories;

  const _ProductTable({required this.products, required this.categories});

  String _categoryName(int? id) {
    if (id == null) return '—';
    try {
      return categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainerHigh),
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('SKU')),
          DataColumn(label: Text('Stock'), numeric: true),
          DataColumn(label: Text('Cost (CDF)'), numeric: true),
          DataColumn(label: Text('Price (CDF)'), numeric: true),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: products.map((p) {
          final isLow = p.stockQuantity <= p.minimumStockLevel;
          return DataRow(
            color: WidgetStateProperty.resolveWith((states) {
              if (isLow) return Colors.orange.withOpacity(0.08);
              return null;
            }),
            cells: [
              DataCell(
                Row(children: [
                  if (isLow) const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                  ),
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                ]),
              ),
              DataCell(Text(_categoryName(p.categoryId))),
              DataCell(Text(p.sku ?? '—')),
              DataCell(Text(p.stockQuantity.toStringAsFixed(2))),
              DataCell(Text(p.costPrice.toStringAsFixed(0))),
              DataCell(Text(p.sellingPrice.toStringAsFixed(0))),
              DataCell(
                Switch(
                  value: p.isActive,
                  onChanged: (val) => context.read<InventoryBloc>().add(
                        ToggleProductActive(p.id, val)),
                ),
              ),
              DataCell(
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<InventoryBloc>(),
                          child: AddEditProductScreen(product: p),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_outlined, size: 20),
                    tooltip: 'Adjust Stock',
                    onPressed: () => _showAdjustStockDialog(context, p),
                  ),
                ]),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context, Product p) {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();
    String selectedReason = 'CORRECTION';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust Stock: ${p.name}'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current stock: ${p.stockQuantity}'),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(
                  labelText: 'Quantity change (use - for reduction)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                items: ['CORRECTION', 'DAMAGE', 'THEFT', 'OPENING_COUNT']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => selectedReason = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (required)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text) ?? 0;
              context.read<InventoryBloc>().add(AdjustStock(
                productId: p.id,
                userId: 1, // TODO: inject current user id
                quantityChange: qty,
                movementType: 'ADJUST',
                reasonCode: selectedReason,
                notes: notesController.text,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
