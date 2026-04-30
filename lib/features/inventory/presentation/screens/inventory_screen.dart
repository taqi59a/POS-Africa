import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../../../core/di/injection.dart' as di;
import '../../../../core/utils/stock_import_export_utils.dart';
import '../bloc/inventory_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
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

  Future<void> _exportStock(BuildContext context) async {
    final state = context.read<InventoryBloc>().state;
    if (state is! InventoryLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait for inventory to load')));
      return;
    }
    try {
      final path = await StockImportExportUtils.exportProducts(state.products);
      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stock exported to: $path')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _importStock(BuildContext context) async {
    try {
      final rows = await StockImportExportUtils.pickAndParseImportFile();
      if (rows == null) return;

      // Get current products for conflict detection
      final db = di.sl<AppDatabase>();
      final existing = await db.select(db.products).get();
      final conflicts = StockImportExportUtils.detectConflicts(rows, existing);

      if (!context.mounted) return;

      // Show import preview dialog
      bool? overwrite;
      if (conflicts.isNotEmpty) {
        overwrite = await _showConflictDialog(context, rows, conflicts);
        if (overwrite == null) return; // user cancelled
      }

      // Apply import
      final result = await StockImportExportUtils.applyImport(
        rows: rows,
        existing: existing,
        db: db,
        overwriteDuplicates: overwrite ?? false,
      );

      if (!context.mounted) return;
      context.read<InventoryBloc>().add(LoadProducts());

      final msg = 'Imported: ${result.imported} new  •  '
          'Updated: ${result.updated}  •  Skipped: ${result.skipped}'
          '${result.errors.isNotEmpty ? '\nErrors: ${result.errors.length}' : ''}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<bool?> _showConflictDialog(
      BuildContext context,
      List<StockExportRow> rows,
      List<ImportConflict> conflicts) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${conflicts.length} Duplicate(s) Found'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following ${conflicts.length} item(s) already exist in inventory '
                'with different values. How would you like to handle them?',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: conflicts.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (_, i) {
                    final c = conflicts[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 20),
                      title: Text(c.incoming.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Conflicting fields: ${c.conflictingFields.join(', ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text('Total items to import: ${rows.length}  •  New: ${rows.length - conflicts.length}  •  Duplicates: ${conflicts.length}',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Skip Duplicates'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Overwrite Duplicates'),
          ),
        ],
      ),
    );
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
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Export Stock to JSON',
            onPressed: () => _exportStock(context),
          ),
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Import Stock from JSON',
            onPressed: () => _importStock(context),
          ),
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
    // Determine current user and role
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    if (currentUser == null) return;

    final qtyController = TextEditingController();
    final notesController = TextEditingController();
    // Default to RECEIVE for stock clerks, CORRECTION for managers/admins
    String selectedReason = 'CORRECTION';
    bool isAdminOrManager = true; // will be confirmed by role name below

    showDialog(
      context: context,
      builder: (ctx) {
        // We use BlocBuilder to get roles from UserBloc if needed;
        // simpler: just use the roleId from SettingsBloc or hardcode check
        // Roles: 1=Admin, 2=Manager — can adjust negative (damage/theft)
        //        3=Cashier, 4=Stock Clerk — can only receive/add
        // This is enforced at the dialog level using roleId
        final roleId = currentUser.roleId;
        // roleId 1 = Admin, 2 = Manager (first two seeded roles)
        isAdminOrManager = roleId != null && roleId <= 2;

        return AlertDialog(
          title: Text('Adjust Stock: ${p.name}'),
          content: StatefulBuilder(
            builder: (ctx2, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Current stock: ${p.stockQuantity.toStringAsFixed(0)} units',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  decoration: InputDecoration(
                    labelText: isAdminOrManager
                        ? 'Quantity change (use - to deduct for loss/damage)'
                        : 'Quantity to receive (+)',
                    border: const OutlineInputBorder(),
                    helperText: isAdminOrManager
                        ? 'Admins/Managers can enter negative values'
                        : 'Stock clerks can only add received goods',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  decoration: const InputDecoration(
                      labelText: 'Reason', border: OutlineInputBorder()),
                  items: [
                    if (isAdminOrManager) ...[
                      const DropdownMenuItem(value: 'CORRECTION', child: Text('Correction')),
                      const DropdownMenuItem(value: 'DAMAGE', child: Text('Damage / Loss')),
                      const DropdownMenuItem(value: 'THEFT', child: Text('Theft')),
                    ],
                    const DropdownMenuItem(value: 'OPENING_COUNT', child: Text('Opening Count')),
                    if (!isAdminOrManager)
                      const DropdownMenuItem(value: 'CORRECTION', child: Text('Stock Received')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedReason = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                      labelText: 'Notes', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyController.text) ?? 0;
                if (qty == 0) return;

                // Block non-admin/manager from entering negative values
                if (!isAdminOrManager && qty < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Only Admins and Managers can deduct stock.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final movementType =
                    qty > 0 ? 'RECEIVE' : 'ADJUST';

                context.read<InventoryBloc>().add(AdjustStock(
                  productId: p.id,
                  userId: currentUser.id,
                  quantityChange: qty,
                  movementType: movementType,
                  reasonCode: selectedReason,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
