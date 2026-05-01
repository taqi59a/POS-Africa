import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../bloc/expense_bloc.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(LoadExpenses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracking')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) return const Center(child: CircularProgressIndicator());
          if (state is ExpensesLoaded) {
            if (state.expenses.isEmpty) return const Center(child: Text('No expenses recorded yet.'));
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.expenses.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final expense = state.expenses[index];
                final category = state.categories.firstWhere((c) => c.id == expense.categoryId, orElse: () => const ExpenseCategory(id: 0, name: 'Other'));
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: const Icon(Icons.money_off, color: Colors.red)),
                  title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${category.name} • ${expense.date.day}/${expense.date.month}/${expense.date.year}'),
                  trailing: Text('FC ${expense.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    int? selectedCatId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Expense'),
        content: BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            final categories = state is ExpensesLoaded ? state.categories : <ExpenseCategory>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount (FC)'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedCatId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => selectedCatId = v,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              context.read<ExpenseBloc>().add(AddExpense(ExpensesCompanion.insert(
                date: DateTime.now(),
                description: descController.text,
                amount: double.tryParse(amountController.text) ?? 0,
                categoryId: Value(selectedCatId),
              )));
              Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
