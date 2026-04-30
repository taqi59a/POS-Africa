import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../reports/presentation/bloc/report_bloc.dart';
import '../../../inventory/presentation/bloc/inventory_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportBloc>().add(LoadDailySalesSummary(DateTime.now()));
    context.read<InventoryBloc>().add(LoadLowStockProducts());
    context.read<InventoryBloc>().add(LoadProducts());
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Sunday','Monday','Tuesday','Wednesday',
                    'Thursday','Friday','Saturday'];
    return '${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Dashboard',
                      style: TextStyle(color: AppTheme.textPrimary,
                          fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppTheme.textMuted, size: 14),
                      const SizedBox(width: 8),
                      Text(_formatDate(),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Metric cards ─────────────────────────────────────────
            BlocBuilder<ReportBloc, ReportState>(
              builder: (context, reportState) {
                final data = reportState is ReportDataState ? reportState : null;
                final revenue  = (data?.dailySummary?['total']  as num?)?.toDouble() ?? 0.0;
                final txCount  = (data?.dailySummary?['count']  as num?)?.toInt()    ?? 0;

                return BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, invState) {
                    final allProducts  = invState is InventoryLoaded ? invState.products : [];
                    final lowStockCount = invState is InventoryLoaded
                        ? invState.products
                            .where((p) => p.stockQuantity <= p.minimumStockLevel)
                            .length
                        : 0;

                    return Row(
                      children: [
                        Expanded(child: _MetricCard(
                          label: "Today's Revenue",
                          value: 'CDF ${revenue.toStringAsFixed(0)}',
                          icon:  Icons.trending_up_rounded,
                          color: AppTheme.accentGreen,
                          showAlert: false,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _MetricCard(
                          label: 'Transactions',
                          value: txCount.toString(),
                          icon:  Icons.receipt_rounded,
                          color: AppTheme.primary,
                          showAlert: false,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _MetricCard(
                          label: 'Total Products',
                          value: allProducts.length.toString(),
                          icon:  Icons.inventory_2_rounded,
                          color: AppTheme.accentViolet,
                          showAlert: false,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _MetricCard(
                          label: 'Low Stock Alerts',
                          value: lowStockCount.toString(),
                          icon:  Icons.warning_amber_rounded,
                          color: lowStockCount > 0 ? AppTheme.accentOrange : AppTheme.accentGreen,
                          showAlert: lowStockCount > 0,
                        )),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),

            // ── Quick Actions ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quick Actions',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAction(
                  label: 'New Sale', icon: Icons.add_shopping_cart_rounded,
                  color: AppTheme.primary,
                  onTap: () => widget.onNavigate?.call(1),
                ),
                _QuickAction(
                  label: 'Add Product', icon: Icons.add_box_rounded,
                  color: AppTheme.accentViolet,
                  onTap: () => widget.onNavigate?.call(2),
                ),
                _QuickAction(
                  label: 'New Customer', icon: Icons.person_add_rounded,
                  color: AppTheme.accentGreen,
                  onTap: () => widget.onNavigate?.call(3),
                ),
                _QuickAction(
                  label: 'Add Expense', icon: Icons.money_off_rounded,
                  color: AppTheme.accentOrange,
                  onTap: () => widget.onNavigate?.call(4),
                ),
                _QuickAction(
                  label: 'View Reports', icon: Icons.bar_chart_rounded,
                  color: AppTheme.accent,
                  onTap: () => widget.onNavigate?.call(5),
                ),
                _QuickAction(
                  label: 'Manage Users', icon: Icons.admin_panel_settings_rounded,
                  color: AppTheme.accentRed,
                  onTap: () => widget.onNavigate?.call(6),
                ),
                _QuickAction(
                  label: 'Settings', icon: Icons.settings_rounded,
                  color: AppTheme.textSecondary,
                  onTap: () => widget.onNavigate?.call(8),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Low-stock warnings ─────────────────────────────────────
            BlocBuilder<InventoryBloc, InventoryState>(
              builder: (context, state) {
                if (state is! InventoryLoaded) return const SizedBox();
                final lowStock = state.products
                    .where((p) => p.stockQuantity <= p.minimumStockLevel)
                    .toList();
                if (lowStock.isEmpty) return const SizedBox();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppTheme.accentOrange, size: 18),
                      const SizedBox(width: 8),
                      const Text('Low Stock Alerts',
                        style: TextStyle(color: AppTheme.textPrimary,
                            fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      _Pill(lowStock.length.toString(), AppTheme.accentOrange),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        children: lowStock.map((p) => _LowStockRow(product: p)).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric card ──────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  final bool     showAlert;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.showAlert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showAlert ? color.withAlpha(100) : AppTheme.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (showAlert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        color.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Alert',
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
            style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Quick action button ───────────────────────────────────────────────────────
class _QuickAction extends StatefulWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width:   160,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.bgCardHover : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? widget.color.withAlpha(120) : AppTheme.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        widget.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(widget.label,
                style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pill badge ────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String text;
  final Color  color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Low stock row ─────────────────────────────────────────────────────────────
class _LowStockRow extends StatelessWidget {
  final dynamic product;
  const _LowStockRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final isLast = false; // handled via Column Children
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: AppTheme.accentOrange, size: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Text(product.name,
              style: const TextStyle(color: AppTheme.textPrimary,
                  fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text('${product.stockQuantity.toStringAsFixed(0)} left',
            style: const TextStyle(color: AppTheme.accentOrange,
                fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Text('min: ${product.minimumStockLevel.toStringAsFixed(0)}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

