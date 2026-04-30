import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/customer_repository.dart';

// EVENTS
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {}

class SearchCustomers extends CustomerEvent {
  final String query;
  const SearchCustomers(this.query);
  @override
  List<Object> get props => [query];
}

class AddCustomer extends CustomerEvent {
  final CustomersCompanion customer;
  const AddCustomer(this.customer);
}

class UpdateCustomer extends CustomerEvent {
  final int id;
  final CustomersCompanion customer;
  const UpdateCustomer(this.id, this.customer);
}

// STATES
abstract class CustomerState extends Equatable {
  const CustomerState();
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}
class CustomerLoading extends CustomerState {}
class CustomerLoaded extends CustomerState {
  final List<Customer> customers;
  const CustomerLoaded(this.customers);
  @override
  List<Object> get props => [customers];
}
class CustomerError extends CustomerState {
  final String message;
  const CustomerError(this.message);
}

// BLOC
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository _repo;

  CustomerBloc(this._repo) : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoad);
    on<SearchCustomers>(_onSearch);
    on<AddCustomer>(_onAdd);
    on<UpdateCustomer>(_onUpdate);
  }

  Future<void> _onLoad(LoadCustomers event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      final customers = await _repo.getAllCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onSearch(SearchCustomers event, Emitter<CustomerState> emit) async {
    try {
      final customers = await _repo.searchCustomers(event.query);
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onAdd(AddCustomer event, Emitter<CustomerState> emit) async {
    try {
      await _repo.addCustomer(event.customer);
      add(LoadCustomers());
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateCustomer event, Emitter<CustomerState> emit) async {
    try {
      await _repo.updateCustomer(event.id, event.customer);
      add(LoadCustomers());
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }
}
