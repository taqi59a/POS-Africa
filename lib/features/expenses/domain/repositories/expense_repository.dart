import '../../../../core/data/database/app_database.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getAllExpenses();
  Future<List<ExpenseCategory>> getAllExpenseCategories();
  Future<int> addExpense(ExpensesCompanion expense);
  Future<int> addExpenseCategory(String name);
  Future<void> deleteExpense(int id);
}
