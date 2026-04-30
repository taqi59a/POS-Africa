import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/change_password_screen.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/inventory/presentation/bloc/inventory_bloc.dart';
import 'features/inventory/presentation/screens/inventory_screen.dart';
import 'features/billing/presentation/bloc/sales_bloc.dart';
import 'features/billing/presentation/screens/sales_screen.dart';
import 'features/customers/presentation/bloc/customer_bloc.dart';
import 'features/customers/presentation/screens/customer_screen.dart';
import 'features/reports/presentation/bloc/report_bloc.dart';
import 'features/reports/presentation/screens/report_screen.dart';
import 'features/expenses/presentation/bloc/expense_bloc.dart';
import 'features/expenses/presentation/screens/expense_screen.dart';
import 'features/audit/presentation/bloc/audit_bloc.dart';
import 'features/audit/presentation/screens/audit_screen.dart';
import 'features/shop/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const CongoPosApp());
}

class CongoPosApp extends StatelessWidget {
  const CongoPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckStatus()),
        ),
        BlocProvider(
          create: (_) => di.sl<SettingsBloc>()..add(LoadSettings()),
        ),
        BlocProvider(
          create: (_) => di.sl<InventoryBloc>()..add(LoadProducts()),
        ),
        BlocProvider(
          create: (_) => di.sl<SalesBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<CustomerBloc>()..add(LoadCustomers()),
        ),
        BlocProvider(
          create: (_) => di.sl<ReportBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<ExpenseBloc>()..add(LoadExpenses()),
        ),
        BlocProvider(
          create: (_) => di.sl<AuditBloc>()..add(LoadAuditLogs()),
        ),
      ],
      child: MaterialApp(
        title: 'Congo POS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (state is AuthAuthenticated) {
          return const DashboardShell();
        } else if (state is AuthRequirePasswordChange) {
          return const ChangePasswordScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  final List<NavigationRailDestination> _destinations = const [
    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
    NavigationRailDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: Text('POS')),
    NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Inventory')),
    NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Customers')),
    NavigationRailDestination(icon: Icon(Icons.money_off_outlined), selectedIcon: Icon(Icons.money_off), label: Text('Expenses')),
    NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('Audit')),
    NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Reports')),
    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
  ];

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const SalesScreen();
      case 2:
        return const InventoryScreen();
      case 3:
        return const CustomerScreen();
      case 4:
        return const ExpenseScreen();
      case 5:
        return const AuditScreen();
      case 6:
        return const ReportScreen();
      case 7:
        return const SettingsScreen();
      default:
        // Placeholders for other pages
        final titles = ['Dashboard', 'POS', 'Inventory', 'Customers', 'Expenses', 'Audit', 'Reports', 'Settings'];
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(titles[index], style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Coming soon — in active development', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: _destinations,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  const Icon(Icons.point_of_sale, size: 36, color: Colors.blueAccent),
                  const SizedBox(height: 4),
                  Text('Congo POS', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildPage(_selectedIndex)),
        ],
      ),
    );
  }
}
