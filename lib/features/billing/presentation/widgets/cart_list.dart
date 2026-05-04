import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sales_bloc.dart';

class CartList extends StatelessWidget {
  const CartList({super.key});

  Future<void> _editUnitPrice(BuildContext context, CartItem item) async {
    final ctrl = TextEditingController(text: item.unitPrice.toStringAsFixed(0));
    final newPrice = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Unit Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Cost floor: FC ${item.product.costPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Unit price (FC)',
                  border: OutlineInputBorder(),
                  prefixText: 'FC ',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(ctrl.text.trim());
                if (parsed == null || parsed <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid price — enter digits only, no spaces or commas (e.g. 225000).'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                if (parsed < item.product.costPrice) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Price cannot be below cost (FC ${item.product.costPrice.toStringAsFixed(0)}).',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, parsed);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (newPrice != null && context.mounted) {
      context.read<SalesBloc>().add(UpdateCartItemUnitPrice(item.product.id, newPrice));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        if (state.cart.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Cart is empty', style: TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: state.cart.length,
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final item = state.cart[index];
            final hasOverride = item.unitPriceOverride != null;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Unit FC ${item.unitPrice.toStringAsFixed(0)}'),
                  if (hasOverride)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Custom',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    tooltip: 'Edit Unit Price',
                    onPressed: () => _editUnitPrice(context, item),
                  ),
                  // Quantity adjustment
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () => context.read<SalesBloc>().add(
                                UpdateCartItemQuantity(item.product.id, item.quantity - 1),
                              ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            item.quantity.toStringAsFixed(0),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () => context.read<SalesBloc>().add(
                                UpdateCartItemQuantity(item.product.id, item.quantity + 1),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'FC ${item.lineTotal.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => context.read<SalesBloc>().add(
                          RemoveFromCart(item.product.id),
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
