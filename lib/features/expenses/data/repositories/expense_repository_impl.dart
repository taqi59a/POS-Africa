import 'package:drift/drift.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepositoryImpl(this._db);

  @override
  Future<List<Expense>> getAllExpenses() =>
    (_db.select(_db.expenses)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();

  @override
  Future<List<ExpenseCategory>> getAllExpenseCategories() =>
    (_db.select(_db.expenseCategories)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  @override
  Future<int> addExpense(ExpensesCompanion expense) =>
    _db.into(_db.expenses).insert(expense);

  @override
  Future<int> addExpenseCategory(String name) =>
    _db.into(_db.expenseCategories).insert(ExpenseCategoriesCompanion.insert(name: name));

  @override
  Future<void> deleteExpense(int id) =>
    (_db.delete(_db.expenses)..where((t) => t.id.equals(id))).go();
}
