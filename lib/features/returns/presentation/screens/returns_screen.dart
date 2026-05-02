import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../bloc/returns_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}';

String _fmtDateTime(DateTime d) =>
    '${_fmtDate(d)}  ${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';

// ─────────────────────────────────────────────────────────────────────────────
// Returns Screen
// ─────────────────────────────────────────────────────────────────────────────

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    context.read<ReturnsBloc>().add(const LoadAllReturns());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReturnsBloc, ReturnsState>(
      listenWhen: (prev, cur) =>
          cur.successMessage != null && prev.successMessage != cur.successMessage,
      listener: (ctx, state) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<ReturnsBloc>().add(const DismissReturnSuccess());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Returns & Refunds'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'New Return',
              onPressed: () => _tabCtrl.animateTo(1),
            ),
          ],
          bottom: TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(icon: Icon(Icons.history_rounded), text: 'Return History'),
              Tab(icon: Icon(Icons.assignment_return_rounded), text: 'New Return'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            const _ReturnHistoryTab(),
            _NewReturnTab(onSuccess: () => _tabCtrl.animateTo(0)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 – Return History
// ─────────────────────────────────────────────────────────────────────────────

class _ReturnHistoryTab extends StatelessWidget {
  const _ReturnHistoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReturnsBloc, ReturnsState>(
      builder: (ctx, state) {
        if (state.isLoading && state.returns.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.returns.isEmpty) {
          return Center(
              child: Text('Error: ${state.error}',
                  style: const TextStyle(color: Colors.red)));
        }
        if (state.returns.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_return_rounded, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('No returns yet',
                    style: TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: state.returns.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) => _ReturnCard(ret: state.returns[i]),
        );
      },
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final Map<String, dynamic> ret;
  const _ReturnCard({required this.ret});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ret['status']?.toString() ?? 'COMPLETED';
    final statusColor = status == 'VOIDED' ? Colors.grey : Colors.green;
    final refund = ret['totalRefundAmount'] as double? ?? 0.0;
    final refundUsd = ret['totalRefundAmountUsd'] as double? ?? 0.0;
    final rate = ret['exchangeRate'] as double? ?? 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.assignment_return_rounded,
                  color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(ret['returnNumber']?.toString() ?? '',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(status,
                            style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ret['customerName']}  •  '
                    '${_fmtDateTime(ret['returnDate'] as DateTime)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    ret['reason']?.toString() ?? '',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${refundUsd.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                ),
                Text(
                  'FC ${refund.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                if (rate > 0)
                  Text(
                    '@ $rate FC/\$',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            if (status == 'COMPLETED')
              IconButton(
                icon: const Icon(Icons.block_rounded, size: 18),
                tooltip: 'Void Return',
                onPressed: () => _confirmVoid(context, ret),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmVoid(
      BuildContext context, Map<String, dynamic> ret) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Void Return'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Voiding ${ret['returnNumber']} will re-deduct the returned stock.'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration:
                    const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Void'),
            ),
          ],
        );
      },
    );
    if (reason != null && reason.isNotEmpty && context.mounted) {
      context
          .read<ReturnsBloc>()
          .add(VoidReturn(ret['id'] as int, reason));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 – New Return
// ─────────────────────────────────────────────────────────────────────────────

class _NewReturnTab extends StatefulWidget {
  final VoidCallback onSuccess;
  const _NewReturnTab({required this.onSuccess});

  @override
  State<_NewReturnTab> createState() => _NewReturnTabState();
}

class _NewReturnTabState extends State<_NewReturnTab> {
  final _searchCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController(text: 'Customer return');
  String _refundMethod = 'CASH';

  // Selected items to return: productId -> {info + qty to return}
  final Map<int, _ReturnItem> _selected = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  double get _exchangeRate {
    final s = context.read<SettingsBloc>().state;
    if (s is SettingsLoaded) {
      return double.tryParse(s.settings['usd_exchange_rate'] ?? '0') ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReturnsBloc, ReturnsState>(
      builder: (ctx, state) {
        final selectedSale = state.selectedSaleForReturn;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Step 1: Search original sale ──
              if (selectedSale == null) ...[
                _SectionHeader(
                    icon: Icons.search_rounded, label: 'Step 1: Find Original Sale'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Scan receipt barcode / invoice # / customer',
                          prefixIcon: Icon(Icons.find_in_page_rounded),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _search(ctx),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _search(ctx),
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        _selected.clear();
                        ctx.read<ReturnsBloc>().add(const ClearSaleForReturn());
                        _searchCtrl.clear();
                      },
                      icon: const Icon(Icons.clear_all_rounded),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state.saleSearchResults.isNotEmpty) ...[
                  Text('${state.saleSearchResults.length} sale(s) found:',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ...state.saleSearchResults
                      .map((s) => _SaleSearchResultCard(
                            sale: s,
                            onSelect: () => ctx
                                .read<ReturnsBloc>()
                                .add(LoadSaleForReturn(s['id'] as int)),
                          )),
                ] else if (_searchCtrl.text.isNotEmpty)
                  const Text('No completed sales found.',
                      style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _SectionHeader(
                    icon: Icons.input_rounded,
                    label: 'Or: Manual Return (no original invoice)'),
                const SizedBox(height: 8),
                _ManualReturnForm(
                  onSubmit: (lines) => _submitReturn(ctx, null, lines),
                  exchangeRate: _exchangeRate,
                ),
              ] else ...[
                // ── Step 2: Select items from original sale ──
                _SelectedSaleHeader(
                  sale: selectedSale,
                  onClear: () {
                    setState(() => _selected.clear());
                    ctx.read<ReturnsBloc>().add(const ClearSaleForReturn());
                  },
                ),
                const SizedBox(height: 12),
                _SectionHeader(
                    icon: Icons.checklist_rounded,
                    label: 'Step 2: Select Items to Return'),
                const SizedBox(height: 8),
                ...(selectedSale['lines'] as List)
                    .cast<Map<String, dynamic>>()
                    .map((line) => _SaleLineReturnRow(
                          line: line,
                          selected: _selected[line['productId'] as int],
                          onChanged: (item) {
                            setState(() {
                              if (item == null) {
                                _selected.remove(line['productId'] as int);
                              } else {
                                _selected[line['productId'] as int] = item;
                              }
                            });
                          },
                        )),
                const SizedBox(height: 16),
                _SectionHeader(
                    icon: Icons.comment_outlined, label: 'Step 3: Return Details'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Return',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonFormField<String>(
                      value: _refundMethod,
                      decoration: const InputDecoration(
                          labelText: 'Refund Method',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8)),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                        DropdownMenuItem(
                            value: 'STORE_CREDIT', child: Text('Store Credit')),
                        DropdownMenuItem(
                            value: 'EXCHANGE', child: Text('Exchange')),
                      ],
                      onChanged: (v) => setState(() => _refundMethod = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ReturnSummaryBar(
                  selected: _selected,
                  exchangeRate: _exchangeRate,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isProcessing || _selected.isEmpty
                        ? null
                        : () => _submitReturn(
                              ctx,
                              selectedSale['id'] as int?,
                              _selected.values.toList(),
                            ),
                    icon: state.isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.assignment_return_rounded),
                    label: const Text('Process Return'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _search(BuildContext ctx) {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    ctx.read<ReturnsBloc>().add(SearchSalesForReturn(q));
  }

  void _submitReturn(
      BuildContext ctx, int? originalSaleId, List<_ReturnItem> items) {
    final authState = context.read<AuthBloc>().state;
    final cashierId = authState is AuthAuthenticated ? authState.user.id : null;

    final lines = items
        .map((item) => ReturnLineInput(
              productId: item.productId,
              productName: item.productName,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              originalSaleLineId: item.originalSaleLineId,
            ))
        .toList();

    ctx.read<ReturnsBloc>().add(SubmitReturn(
          cashierId: cashierId,
          originalSaleId: originalSaleId,
          reason: _reasonCtrl.text.trim().isEmpty
              ? 'Customer return'
              : _reasonCtrl.text.trim(),
          refundMethod: _refundMethod,
          exchangeRate: _exchangeRate,
          lines: lines,
        ));

    setState(() => _selected.clear());
    widget.onSuccess();
  }
}

// ── Return Item model (local, screen-scoped) ─────────────────────────────────

class _ReturnItem {
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final int? originalSaleLineId;

  const _ReturnItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.originalSaleLineId,
  });

  double get lineTotal => quantity * unitPrice;
}

// ── Widgets ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}

class _SaleSearchResultCard extends StatelessWidget {
  final Map<String, dynamic> sale;
  final VoidCallback onSelect;

  const _SaleSearchResultCard({required this.sale, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final total = sale['grandTotal'] as double? ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading:
            const Icon(Icons.receipt_long_rounded, color: Colors.blueGrey),
        title: Text(sale['transactionNumber']?.toString() ?? ''),
        subtitle: Text(
            '${sale['customerName']}  •  ${_fmtDate(sale['saleDate'] as DateTime)}'),
        trailing: Text('FC ${total.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: onSelect,
      ),
    );
  }
}

class _SelectedSaleHeader extends StatelessWidget {
  final Map<String, dynamic> sale;
  final VoidCallback onClear;

  const _SelectedSaleHeader({required this.sale, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.linked_camera_rounded, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice: ${sale['transactionNumber']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                      '${sale['customerName'] ?? 'Walk-in'}  •  '
                      '${_fmtDateTime(sale['saleDate'] as DateTime)}',
                      style: const TextStyle(fontSize: 12)),
                  Text(
                      'Original Total: \$${(sale['grandTotalUsd'] as double? ?? 0).toStringAsFixed(2)}  '
                      '(FC ${(sale['grandTotal'] as double? ?? 0).toStringAsFixed(0)})',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleLineReturnRow extends StatefulWidget {
  final Map<String, dynamic> line;
  final _ReturnItem? selected;
  final ValueChanged<_ReturnItem?> onChanged;

  const _SaleLineReturnRow({
    required this.line,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_SaleLineReturnRow> createState() => _SaleLineReturnRowState();
}

class _SaleLineReturnRowState extends State<_SaleLineReturnRow> {
  bool _checked = false;
  late TextEditingController _qtyCtrl;

  final double _origQty = 0;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
        text: (widget.line['quantity'] as double? ?? 1).toStringAsFixed(0));
    _checked = widget.selected != null;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _fire() {
    if (!_checked) {
      widget.onChanged(null);
      return;
    }
    final qty =
        double.tryParse(_qtyCtrl.text) ?? widget.line['quantity'] as double;
    final maxQty = widget.line['quantity'] as double;
    final clamped = qty.clamp(0.01, maxQty);
    widget.onChanged(_ReturnItem(
      productId: widget.line['productId'] as int,
      productName: widget.line['productName']?.toString() ?? '',
      quantity: clamped,
      unitPrice: widget.line['unitPrice'] as double? ?? 0,
      originalSaleLineId: widget.line['id'] as int?,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final origQty = widget.line['quantity'] as double? ?? 1;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Checkbox(
            value: _checked,
            onChanged: (v) {
              setState(() => _checked = v ?? false);
              _fire();
            },
          ),
          Expanded(
            child: Text(widget.line['productName']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text(
              'FC ${(widget.line['unitPrice'] as double? ?? 0).toStringAsFixed(0)} × ',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _qtyCtrl,
              enabled: _checked,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Qty',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _fire(),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '/ ${origQty.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ReturnSummaryBar extends StatelessWidget {
  final Map<int, _ReturnItem> selected;
  final double exchangeRate;

  const _ReturnSummaryBar(
      {required this.selected, required this.exchangeRate});

  @override
  Widget build(BuildContext context) {
    final total =
        selected.values.fold<double>(0, (s, i) => s + i.lineTotal);
    final usd = exchangeRate > 0 ? total / exchangeRate : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${selected.length} item type(s)  •  '
            '${selected.values.fold<double>(0, (s, i) => s + i.quantity).toStringAsFixed(0)} units',
            style: const TextStyle(color: Colors.grey),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${usd.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text('FC ${total.toStringAsFixed(0)}',
                  style:
                      const TextStyle(fontSize: 13, color: Colors.grey)),
              if (exchangeRate > 0)
                Text('@ $exchangeRate FC/\$',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Manual Return Form ────────────────────────────────────────────────────────

class _ManualReturnForm extends StatefulWidget {
  final void Function(List<_ReturnItem>) onSubmit;
  final double exchangeRate;

  const _ManualReturnForm(
      {required this.onSubmit, required this.exchangeRate});

  @override
  State<_ManualReturnForm> createState() => _ManualReturnFormState();
}

class _ManualReturnFormState extends State<_ManualReturnForm> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _reasonCtrl = TextEditingController(text: 'Customer return');
  String _refundMethod = 'CASH';
  final List<_ReturnItem> _items = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final qty = double.tryParse(_qtyCtrl.text) ?? 1;
    if (name.isEmpty || price <= 0) return;

    setState(() {
      _items.add(_ReturnItem(
        productId: -DateTime.now().millisecondsSinceEpoch,
        productName: name,
        quantity: qty,
        unitPrice: price,
      ));
      _nameCtrl.clear();
      _priceCtrl.clear();
      _qtyCtrl.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0, (s, i) => s + i.lineTotal);
    final usd = widget.exchangeRate > 0 ? total / widget.exchangeRate : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Product / Item Name',
                    border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Price (FC)',
                    border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Qty', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _addItem, child: const Text('Add')),
          ],
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 10),
          ..._items.asMap().entries.map((e) => ListTile(
                dense: true,
                title: Text(e.value.productName),
                subtitle: Text(
                    '${e.value.quantity.toStringAsFixed(0)} × FC ${e.value.unitPrice.toStringAsFixed(0)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('FC ${e.value.lineTotal.toStringAsFixed(0)}'),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => setState(() => _items.removeAt(e.key)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonFormField<String>(
                value: _refundMethod,
                decoration: const InputDecoration(
                    labelText: 'Refund',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  DropdownMenuItem(
                      value: 'STORE_CREDIT', child: Text('Store Credit')),
                  DropdownMenuItem(
                      value: 'EXCHANGE', child: Text('Exchange')),
                ],
                onChanged: (v) => setState(() => _refundMethod = v!),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${usd.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('FC ${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _items.isEmpty
                    ? null
                    : () => widget.onSubmit(_items),
                icon: const Icon(Icons.assignment_return_rounded, size: 18),
                label: const Text('Submit'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
