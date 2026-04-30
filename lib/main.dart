import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/utils/db_backup_utils.dart';
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
import 'features/users/presentation/bloc/user_bloc.dart';
import 'features/users/presentation/screens/user_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbBackupUtils.applyPendingRestoreIfAny();
  await di.initDependencies();
  runApp(const CongoPosApp());
}

class CongoPosApp extends StatelessWidget {
  const CongoPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(AuthCheckStatus())),
        BlocProvider(create: (_) => di.sl<SettingsBloc>()..add(LoadSettings())),
        BlocProvider(create: (_) => di.sl<InventoryBloc>()..add(LoadProducts())),
        BlocProvider(create: (_) => di.sl<SalesBloc>()),
        BlocProvider(create: (_) => di.sl<CustomerBloc>()..add(LoadCustomers())),
        BlocProvider(create: (_) => di.sl<ReportBloc>()),
        BlocProvider(create: (_) => di.sl<ExpenseBloc>()..add(LoadExpenses())),
        BlocProvider(create: (_) => di.sl<AuditBloc>()..add(LoadAuditLogs())),
        BlocProvider(create: (_) => di.sl<UserBloc>()..add(LoadUsers())),
      ],
      child: MaterialApp(
        title: 'POS Africa',
        theme:      AppTheme.dark,
        darkTheme:  AppTheme.dark,
        themeMode:  ThemeMode.dark,
        home:       const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// ── Auth gate ───────────────────────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.bgDeep,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }
        if (state is AuthAuthenticated)          return const DashboardShell();
        if (state is AuthRequirePasswordChange)  return const ChangePasswordScreen();
        return const LoginScreen();
      },
    );
  }
}

// ── Dashboard shell ─────────────────────────────────────────────────────────
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int  _selectedIndex = 0;
  bool _sidebarExpanded = true;

  static const _items = <_NavItem>[
    _NavItem(Icons.dashboard_rounded,           'Dashboard'),
    _NavItem(Icons.point_of_sale_rounded,       'Point of Sale'),
    _NavItem(Icons.inventory_2_rounded,         'Inventory'),
    _NavItem(Icons.people_rounded,              'Customers'),
    _NavItem(Icons.receipt_long_rounded,        'Expenses'),
    _NavItem(Icons.bar_chart_rounded,           'Reports'),
    _NavItem(Icons.admin_panel_settings_rounded,'Users'),
    _NavItem(Icons.manage_history_rounded,      'Audit Log'),
    _NavItem(Icons.settings_rounded,            'Settings'),
  ];

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return DashboardScreen(onNavigate: (i) => setState(() => _selectedIndex = i));
      case 1: return const SalesScreen();
      case 2: return const InventoryScreen();
      case 3: return const CustomerScreen();
      case 4: return const ExpenseScreen();
      case 5: return const ReportScreen();
      case 6: return const UserManagementScreen();
      case 7: return const AuditScreen();
      case 8: return const SettingsScreen();
      default: return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Row(
        children: [
          _FuturisticSidebar(
            items:           _items,
            selectedIndex:   _selectedIndex,
            expanded:        _sidebarExpanded,
            onSelect:        (i) => setState(() => _selectedIndex = i),
            onToggle:        () => setState(() => _sidebarExpanded = !_sidebarExpanded),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _buildPage(_selectedIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Navigation item data ────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem(this.icon, this.label);
}

// ── Custom futuristic sidebar ────────────────────────────────────────────────
class _FuturisticSidebar extends StatelessWidget {
  final List<_NavItem>   items;
  final int              selectedIndex;
  final bool             expanded;
  final ValueChanged<int> onSelect;
  final VoidCallback     onToggle;

  const _FuturisticSidebar({
    required this.items,
    required this.selectedIndex,
    required this.expanded,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final w = expanded ? 220.0 : 72.0;
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.username
        : 'User';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: w,
      color: AppTheme.bgSidebar,
      child: Column(
        children: [
          // ── Brand header ─────────────────────────────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.point_of_sale_rounded,
                      color: Colors.white, size: 18),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('POS Africa',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      expanded
                          ? Icons.keyboard_double_arrow_left_rounded
                          : Icons.keyboard_double_arrow_right_rounded,
                      color: AppTheme.textMuted, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation items ─────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final isSelected = i == selectedIndex;
                return _SidebarItem(
                  item:       items[i],
                  isSelected: isSelected,
                  expanded:   expanded,
                  onTap:      () => onSelect(i),
                );
              },
            ),
          ),

          // ── User + Logout ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryGlow,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(userName,
                      style: const TextStyle(color: AppTheme.textSecondary,
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Sign Out',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.logout_rounded,
                          color: AppTheme.textMuted, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single sidebar nav item ──────────────────────────────────────────────────
class _SidebarItem extends StatefulWidget {
  final _NavItem  item;
  final bool      isSelected;
  final bool      expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? AppTheme.primaryGlow
        : (_hovered ? AppTheme.borderSubtle : Colors.transparent);
    final iconColor =
        widget.isSelected ? AppTheme.primary : AppTheme.textMuted;
    final textColor =
        widget.isSelected ? AppTheme.textPrimary : AppTheme.textSecondary;

    return MouseRegion(
      onEnter:  (_) => setState(() => _hovered = true),
      onExit:   (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color:        bg,
            borderRadius: BorderRadius.circular(10),
            border: widget.isSelected
                ? Border.all(color: AppTheme.borderAccent, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, color: iconColor, size: 20),
              if (widget.expanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.item.label,
                    style: TextStyle(
                      color:      textColor,
                      fontSize:   13,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbBackupUtils.applyPendingRestoreIfAny();
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
        return DashboardScreen(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
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
