import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../bloc/inventory_bloc.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.product != null;

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  String _unitOfMeasure = 'piece';
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _nameController.text = p.name;
      _skuController.text = p.sku ?? '';
      _barcodeController.text = p.barcode ?? '';
      _costPriceController.text = p.costPrice.toString();
      _sellingPriceController.text = p.sellingPrice.toString();
      _stockController.text = p.stockQuantity.toString();
      _minStockController.text = p.minimumStockLevel.toString();
      _unitOfMeasure = p.unitOfMeasure;
      _selectedCategoryId = p.categoryId;
    }
    // Ensure categories are loaded
    context.read<InventoryBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final companion = ProductsCompanion(
      name: Value(_nameController.text.trim()),
      sku: Value(_skuController.text.trim().isEmpty ? null : _skuController.text.trim()),
      barcode: Value(_barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim()),
      costPrice: Value(double.tryParse(_costPriceController.text) ?? 0),
      sellingPrice: Value(double.tryParse(_sellingPriceController.text) ?? 0),
      stockQuantity: Value(double.tryParse(_stockController.text) ?? 0),
      minimumStockLevel: Value(double.tryParse(_minStockController.text) ?? 5),
      unitOfMeasure: Value(_unitOfMeasure),
      categoryId: Value(_selectedCategoryId),
    );

    if (_isEditing) {
      context.read<InventoryBloc>().add(UpdateProduct(widget.product!.id, companion));
    } else {
      context.read<InventoryBloc>().add(AddProduct(companion));
    }

    Navigator.pop(context);
  }

  InputDecoration _field(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product'),
        actions: [
          FilledButton.icon(
            onPressed: _onSave,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          final categories = state is InventoryLoaded ? state.categories : <Category>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Basic Info', style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: _field('Product Name *'),
                        validator: (v) => v!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: TextFormField(controller: _skuController, decoration: _field('SKU'))),
                        const SizedBox(width: 16),
                        Expanded(child: TextFormField(controller: _barcodeController, decoration: _field('Barcode'))),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _unitOfMeasure,
                            decoration: _field('Unit of Measure'),
                            items: ['piece', 'kg', 'litre', 'box', 'pack', 'dozen']
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) => setState(() => _unitOfMeasure = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _selectedCategoryId,
                            decoration: _field('Category'),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('None')),
                              ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                            ],
                            onChanged: (v) => setState(() => _selectedCategoryId = v),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      Text('Pricing (CDF)', style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _costPriceController,
                          decoration: _field('Cost / Purchase Price'),
                          keyboardType: TextInputType.number,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: TextFormField(
                          controller: _sellingPriceController,
                          decoration: _field('Selling Price *'),
                          keyboardType: TextInputType.number,
                          validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter valid price' : null,
                        )),
                      ]),
                      const SizedBox(height: 24),
                      Text('Stock Levels', style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _stockController,
                          decoration: _field('Current Stock Quantity'),
                          keyboardType: TextInputType.number,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: TextFormField(
                          controller: _minStockController,
                          decoration: _field('Minimum Stock Alert Level'),
                          keyboardType: TextInputType.number,
                        )),
                      ]),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _onSave,
                          icon: const Icon(Icons.save),
                          label: Text(_isEditing ? 'Save Changes' : 'Add Product',
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
