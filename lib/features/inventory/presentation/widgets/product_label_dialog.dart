import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/data/database/app_database.dart';

/// Previews and prints a thermal product label.
/// Label format (58 mm or 80 mm thermal):
///   Line 1 — Product name  (big, bold, centred)
///   Line 2 — Price in FC   (large, centred)
///   Optional line 3 — SKU in small text
class ProductLabelDialog extends StatelessWidget {
  const ProductLabelDialog({super.key, required this.product});

  final Product product;

  // ── helpers ────────────────────────────────────────────────────────────────

  static const double _widthMm = 58.0;
  static const double _marginMm = 4.0;

  Future<void> _printLabel() async {
    final doc = pw.Document();

    final pageWidth = _widthMm * PdfPageFormat.mm;
    final margin = _marginMm * PdfPageFormat.mm;

    doc.addPage(
      pw.Page(
        pageFormat:
            PdfPageFormat(pageWidth, double.infinity, marginAll: margin),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            // ── Product name ─────────────────────────────────────────────────
            pw.Center(
              child: pw.Text(
                product.name,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 6),
            // ── Price ────────────────────────────────────────────────────────
            pw.Center(
              child: pw.Text(
                'FC  ${product.sellingPrice.toStringAsFixed(0)}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            // ── SKU (optional) ───────────────────────────────────────────────
            if (product.sku != null && product.sku!.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  product.sku!,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
            pw.SizedBox(height: 4),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'Label_${product.name.replaceAll(' ', '_')}',
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.label_outline),
          const SizedBox(width: 8),
          const Text('Product Label'),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Preview card ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 0.8),
                  const SizedBox(height: 8),
                  Text(
                    'FC  ${product.sellingPrice.toStringAsFixed(0)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (product.sku != null && product.sku!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      product.sku!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Label width: ${_widthMm.toStringAsFixed(0)} mm thermal',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.print_outlined, size: 18),
          label: const Text('Print Label'),
          onPressed: () {
            Navigator.of(context).pop();
            _printLabel();
          },
        ),
      ],
    );
  }

  /// Convenience helper — show the dialog from any [BuildContext].
  static Future<void> show(BuildContext context, Product product) {
    return showDialog(
      context: context,
      builder: (_) => ProductLabelDialog(product: product),
    );
  }
}
