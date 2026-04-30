import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sales_bloc.dart';

class CartList extends StatelessWidget {
  const CartList({super.key});

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
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('CDF ${item.product.sellingPrice.toStringAsFixed(0)} / unit'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      'CDF ${item.lineTotal.toStringAsFixed(0)}',
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
