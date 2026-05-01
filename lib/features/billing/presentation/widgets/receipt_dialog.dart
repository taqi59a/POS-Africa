import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../bloc/sales_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

class ReceiptDialog extends StatelessWidget {
  final CompletedSaleReceipt receipt;

  const ReceiptDialog({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final settings =
            settingsState is SettingsLoaded ? settingsState.settings : <String, String>{};
        final businessName = settings['business_name'] ?? 'My Business';
        final businessAddress = settings['business_address'] ?? '';
        final businessPhone = settings['business_phone'] ?? '';
        final logoPath = settings['business_logo_path'] ?? '';
        final dualCurrency = (settings['dual_currency_enabled'] ?? 'false') == 'true';
        final footer = settings['receipt_footer'] ?? 'Thank you for your purchase!';
        final vatEnabled = (settings['vat_enabled'] ?? 'false') == 'true';
        final vatPct = double.tryParse(settings['vat_percentage'] ?? '16') ?? 16;
        final vatNumber = settings['business_vat_number'] ?? '';
        final vatAmount = receipt.vatAmount;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header bar ──
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sale Complete!',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer)),
                            Text(receipt.transactionNumber,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer.withOpacity(0.75))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.print_outlined),
                        tooltip: 'Print Receipt',
                        color: colorScheme.onPrimaryContainer,
                        onPressed: () => _printReceipt(settings, receipt),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: colorScheme.onPrimaryContainer,
                        onPressed: () {
                          context.read<SalesBloc>().add(DismissSaleReceipt());
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),

                // ── Receipt body ──
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        children: [
                          // Logo
                          if (logoPath.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(logoPath),
                                  height: 70,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ),

                          // Business info
                          Text(businessName,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                          if (businessAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(businessAddress,
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center),
                          ],
                          if (businessPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(businessPhone,
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center),
                          ],
                          if (vatEnabled && vatNumber.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('VAT No: $vatNumber',
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: 12),
                          const Divider(),

                          // Customer row (if not walk-in)
                          if (receipt.customerName != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14),
                                const SizedBox(width: 4),
                                Text(receipt.customerName!,
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],

                          // Date / cashier row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${receipt.saleDate.day.toString().padLeft(2,'0')}/'
                                '${receipt.saleDate.month.toString().padLeft(2,'0')}/'
                                '${receipt.saleDate.year}  '
                                '${receipt.saleDate.hour.toString().padLeft(2,'0')}:'
                                '${receipt.saleDate.minute.toString().padLeft(2,'0')}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(receipt.transactionNumber,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(),

                          // ── Line items ──
                          ...receipt.items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(item.product.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                        Text(
                                          'FC ${item.lineTotal.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '  ${item.quantity.toStringAsFixed(0)} × FC ${item.product.sellingPrice.toStringAsFixed(0)}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                        if (dualCurrency)
                                          Text(
                                            '\$${(item.lineTotal / receipt.exchangeRate).toStringAsFixed(2)}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),

                          const Divider(),

                          // ── Totals ──
                          _Row(label: 'Subtotal', value: 'FC ${receipt.subtotal.toStringAsFixed(0)}'),
                          if (receipt.discount > 0)
                            _Row(
                                label: 'Discount',
                                value: '- FC ${receipt.discount.toStringAsFixed(0)}',
                                valueColor: Colors.orange),
                          if (vatEnabled && vatAmount > 0)
                            _Row(
                                label: 'VAT ($vatPct% incl.)',
                                value: 'FC ${vatAmount.toStringAsFixed(0)}'),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'FC ${receipt.grandTotal.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary),
                                  ),
                                  if (dualCurrency)
                                    Text(
                                      '\$${receipt.grandTotalUsd.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),

                          // ── Payment info ──
                          _Row(label: 'Method', value: receipt.paymentMethod),
                          _Row(
                              label: 'Tendered',
                              value: 'FC ${receipt.amountTendered.toStringAsFixed(0)}'),
                          if (receipt.changeDue > 0)
                            _Row(
                                label: 'Change Due',
                                value: 'FC ${receipt.changeDue.toStringAsFixed(0)}',
                                valueColor: Colors.green,
                                bold: true),
                          const SizedBox(height: 4),
                          if (receipt.exchangeRate > 0)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Rate: ${receipt.exchangeRate.toStringAsFixed(0)} FC/\$',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Footer
                          Text(footer,
                              style:
                                  theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Action bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _printReceipt(settings, receipt),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Print'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            context.read<SalesBloc>().add(DismissSaleReceipt());
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          label: const Text('New Sale'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _printReceipt(
      Map<String, String> settings, CompletedSaleReceipt r) async {
    final businessName = settings['business_name'] ?? 'My Business';
    final businessAddress = settings['business_address'] ?? '';
    final businessPhone = settings['business_phone'] ?? '';
    final logoPath = settings['business_logo_path'] ?? '';
    final dualCurrency = (settings['dual_currency_enabled'] ?? 'false') == 'true';
    final footer = settings['receipt_footer'] ?? 'Thank you for your purchase!';
    final widthMm = double.tryParse(settings['receipt_paper_width_mm'] ?? '80') ?? 80;

    final doc = pw.Document();

    pw.MemoryImage? logoImg;
    if (logoPath.isNotEmpty) {
      try {
        final f = File(logoPath);
        if (await f.exists()) {
          logoImg = pw.MemoryImage(await f.readAsBytes());
        }
      } catch (_) {}
    }

    final pageWidth = widthMm * PdfPageFormat.mm;
    final margin    = (widthMm >= 100 ? 8.0 : 4.0) * PdfPageFormat.mm;

    pw.TextStyle bold(double size) =>
        pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold);
    pw.TextStyle normal(double size) => pw.TextStyle(fontSize: size);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(pageWidth, double.infinity, marginAll: margin),
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoImg != null) ...[
              pw.Center(child: pw.Image(logoImg, height: 55, fit: pw.BoxFit.contain)),
              pw.SizedBox(height: 6),
            ],
            pw.Text(businessName, style: bold(14), textAlign: pw.TextAlign.center),
            if (businessAddress.isNotEmpty)
              pw.Text(businessAddress,
                  style: normal(9), textAlign: pw.TextAlign.center),
            if (businessPhone.isNotEmpty)
              pw.Text(businessPhone,
                  style: normal(9), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(r.transactionNumber, style: normal(8)),
                pw.Text(
                    '${r.saleDate.day.toString().padLeft(2,'0')}/'
                    '${r.saleDate.month.toString().padLeft(2,'0')}/'
                    '${r.saleDate.year} '
                    '${r.saleDate.hour.toString().padLeft(2,'0')}:'
                    '${r.saleDate.minute.toString().padLeft(2,'0')}',
                    style: normal(8)),
              ],
            ),
            pw.Divider(thickness: 0.5),
            // Items
            ...r.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(child: pw.Text(item.product.name, style: normal(9))),
                          pw.Text('FC ${item.lineTotal.toStringAsFixed(0)}',
                              style: normal(9)),
                        ],
                      ),
                      pw.Text(
                          '  ${item.quantity.toStringAsFixed(0)} × FC ${item.product.sellingPrice.toStringAsFixed(0)}',
                          style: normal(8)),
                    ],
                  ),
                )),
            pw.Divider(thickness: 0.5),
            _pdfRow('Subtotal:', 'FC ${r.subtotal.toStringAsFixed(0)}', normal),
            if (r.discount > 0)
              _pdfRow('Discount:', '- FC ${r.discount.toStringAsFixed(0)}', normal),
            if (r.vatAmount > 0)
              _pdfRow('VAT (incl.):', 'FC ${r.vatAmount.toStringAsFixed(0)}', normal),
            pw.SizedBox(height: 3),
            _pdfRow('TOTAL:', 'FC ${r.grandTotal.toStringAsFixed(0)}', bold),
            if (dualCurrency)
              _pdfRow('USD:', '\$${r.grandTotalUsd.toStringAsFixed(2)}', normal),
            pw.Divider(thickness: 0.5),
            _pdfRow('Payment:', r.paymentMethod, normal),
            _pdfRow('Tendered:', 'FC ${r.amountTendered.toStringAsFixed(0)}', normal),
            if (r.changeDue > 0)
              _pdfRow('Change:', 'FC ${r.changeDue.toStringAsFixed(0)}', normal),
            if (r.exchangeRate > 0)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Rate: ${r.exchangeRate.toStringAsFixed(0)} FC/\$',
                  style: normal(7),
                ),
              ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(footer,
                  style: normal(8), textAlign: pw.TextAlign.center),
            ),
          ],
        );
      },
    ));

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  pw.Widget _pdfRow(
      String label, String value, pw.TextStyle Function(double) style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style(9)),
        pw.Text(value, style: style(9)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _Row(
      {required this.label,
      required this.value,
      this.valueColor,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: valueColor)),
        ],
      ),
    );
  }
}
