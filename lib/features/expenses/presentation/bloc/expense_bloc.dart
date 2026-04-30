import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/expense_repository.dart';

// EVENTS
abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();
  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {}
class LoadExpenseCategories extends ExpenseEvent {}
class AddExpense extends ExpenseEvent {
  final ExpensesCompanion expense;
  const AddExpense(this.expense);
}
class AddExpenseCategory extends ExpenseEvent {
  final String name;
  const AddExpenseCategory(this.name);
}

// STATES
abstract class ExpenseState extends Equatable {
  const ExpenseState();
  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}
class ExpenseLoading extends ExpenseState {}
class ExpensesLoaded extends ExpenseState {
  final List<Expense> expenses;
  final List<ExpenseCategory> categories;
  const ExpensesLoaded(this.expenses, this.categories);
  @override
  List<Object> get props => [expenses, categories];
}
class ExpenseError extends ExpenseState {
  final String message;
  const ExpenseError(this.message);
}

// BLOC
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repo;

  ExpenseBloc(this._repo) : super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoad);
    on<AddExpense>(_onAdd);
    on<AddExpenseCategory>(_onAddCategory);
  }

  Future<void> _onLoad(LoadExpenses event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    try {
      final expenses = await _repo.getAllExpenses();
      final categories = await _repo.getAllExpenseCategories();
      emit(ExpensesLoaded(expenses, categories));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onAdd(AddExpense event, Emitter<ExpenseState> emit) async {
    try {
      await _repo.addExpense(event.expense);
      add(LoadExpenses());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onAddCategory(AddExpenseCategory event, Emitter<ExpenseState> emit) async {
    try {
      await _repo.addExpenseCategory(event.name);
      add(LoadExpenses());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }
}
