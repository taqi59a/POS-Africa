import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../data/database/app_database.dart';

/// Represents one product row for import/export purposes.
class StockExportRow {
  final int?   id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? unitOfMeasure;
  final double costPrice;
  final double sellingPrice;
  final double stockQuantity;
  final double minimumStockLevel;
  final bool   isActive;

  const StockExportRow({
    this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.unitOfMeasure,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.minimumStockLevel,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
    'id':               id,
    'name':             name,
    'sku':              sku,
    'barcode':          barcode,
    'unitOfMeasure':    unitOfMeasure ?? 'piece',
    'costPrice':        costPrice,
    'sellingPrice':     sellingPrice,
    'stockQuantity':    stockQuantity,
    'minimumStockLevel':minimumStockLevel,
    'isActive':         isActive,
  };

  factory StockExportRow.fromJson(Map<String, dynamic> json) => StockExportRow(
    id:               json['id'] as int?,
    name:             (json['name'] ?? '').toString(),
    sku:              json['sku'] as String?,
    barcode:          json['barcode'] as String?,
    unitOfMeasure:    json['unitOfMeasure'] as String?,
    costPrice:        (json['costPrice'] ?? 0.0).toDouble(),
    sellingPrice:     (json['sellingPrice'] ?? 0.0).toDouble(),
    stockQuantity:    (json['stockQuantity'] ?? 0.0).toDouble(),
    minimumStockLevel:(json['minimumStockLevel'] ?? 5.0).toDouble(),
    isActive:         (json['isActive'] ?? true) == true,
  );

  factory StockExportRow.fromProduct(Product p) => StockExportRow(
    id:               p.id,
    name:             p.name,
    sku:              p.sku,
    barcode:          p.barcode,
    unitOfMeasure:    p.unitOfMeasure,
    costPrice:        p.costPrice,
    sellingPrice:     p.sellingPrice,
    stockQuantity:    p.stockQuantity,
    minimumStockLevel:p.minimumStockLevel,
    isActive:         p.isActive,
  );
}

/// Result of an import operation.
class ImportResult {
  final int imported;
  final int updated;
  final int skipped;
  final List<String> errors;
  ImportResult({
    required this.imported,
    required this.updated,
    required this.skipped,
    required this.errors,
  });
}

/// Describes a duplicate/conflict found during import pre-check.
class ImportConflict {
  final StockExportRow incoming;
  final Product        existing;
  /// Specific fields that differ
  final List<String> conflictingFields;

  const ImportConflict({
    required this.incoming,
    required this.existing,
    required this.conflictingFields,
  });
}

class StockImportExportUtils {
  /// Export all products to a user-chosen JSON file.
  /// Returns the saved file path, or null if user cancelled.
  static Future<String?> exportProducts(List<Product> products) async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose export destination',
    );
    if (dir == null) return null;

    final ts = _timestamp(DateTime.now());
    final file = File(p.join(dir, 'POS_Africa_Stock_$ts.json'));
    final rows = products.map((p) => StockExportRow.fromProduct(p).toJson()).toList();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({'exported_at': ts, 'products': rows}),
    );
    return file.path;
  }

  /// Pick a JSON file and parse it, returning the list of rows.
  static Future<List<StockExportRow>?> pickAndParseImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
      dialogTitle: 'Select stock export file',
    );
    if (result == null || result.files.single.path == null) return null;

    final content = await File(result.files.single.path!).readAsString();
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final list    = decoded['products'] as List<dynamic>;
    return list.map((e) => StockExportRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Find conflicts between incoming rows and existing products.
  /// A conflict exists when the same SKU or name exists but has differing values
  /// in any field.
  static List<ImportConflict> detectConflicts(
      List<StockExportRow> incoming, List<Product> existing) {
    final conflicts = <ImportConflict>[];

    for (final row in incoming) {
      // Match by SKU first, then by name
      Product? match;
      if (row.sku != null && row.sku!.isNotEmpty) {
        match = existing.where((e) => e.sku == row.sku).firstOrNull;
      }
      match ??= existing.where((e) => e.name.toLowerCase() == row.name.toLowerCase()).firstOrNull;

      if (match == null) continue;

      final diff = <String>[];
      if (match.name != row.name) diff.add('name');
      if ((match.sku ?? '') != (row.sku ?? '')) diff.add('sku');
      if ((match.barcode ?? '') != (row.barcode ?? '')) diff.add('barcode');
      if ((match.unitOfMeasure) != (row.unitOfMeasure ?? 'piece')) diff.add('unitOfMeasure');
      if ((match.costPrice - row.costPrice).abs() > 0.001) diff.add('costPrice');
      if ((match.sellingPrice - row.sellingPrice).abs() > 0.001) diff.add('sellingPrice');
      if ((match.stockQuantity - row.stockQuantity).abs() > 0.001) diff.add('stockQuantity');
      if ((match.minimumStockLevel - row.minimumStockLevel).abs() > 0.001) diff.add('minimumStockLevel');
      if (match.isActive != row.isActive) diff.add('isActive');

      if (diff.isNotEmpty) {
        conflicts.add(ImportConflict(incoming: row, existing: match, conflictingFields: diff));
      }
    }
    return conflicts;
  }

  /// Apply import: insert new rows, update existing ones (sku/name matched).
  static Future<ImportResult> applyImport({
    required List<StockExportRow> rows,
    required List<Product> existing,
    required AppDatabase db,
    required bool overwriteDuplicates,
  }) async {
    int imported = 0;
    int updated  = 0;
    int skipped  = 0;
    final errors = <String>[];

    for (final row in rows) {
      try {
        // Find existing match
        Product? match;
        if (row.sku != null && row.sku!.isNotEmpty) {
          match = existing.where((e) => e.sku == row.sku).firstOrNull;
        }
        match ??= existing.where((e) => e.name.toLowerCase() == row.name.toLowerCase()).firstOrNull;

        if (match != null) {
          if (!overwriteDuplicates) {
            skipped++;
            continue;
          }
          // Update existing
          await (db.update(db.products)..where((t) => t.id.equals(match!.id))).write(
            ProductsCompanion(
              name:             drift.Value(row.name),
              sku:              drift.Value(row.sku),
              barcode:          drift.Value(row.barcode),
              unitOfMeasure:    drift.Value(row.unitOfMeasure ?? 'piece'),
              costPrice:        drift.Value(row.costPrice),
              sellingPrice:     drift.Value(row.sellingPrice),
              stockQuantity:    drift.Value(row.stockQuantity),
              minimumStockLevel:drift.Value(row.minimumStockLevel),
              isActive:         drift.Value(row.isActive),
              updatedAt:        drift.Value(DateTime.now()),
            ),
          );
          updated++;
        } else {
          // Insert new
          await db.into(db.products).insert(
            ProductsCompanion.insert(
              name:             row.name,
              sku:              drift.Value(row.sku),
              barcode:          drift.Value(row.barcode),
              unitOfMeasure:    drift.Value(row.unitOfMeasure ?? 'piece'),
              costPrice:        drift.Value(row.costPrice),
              sellingPrice:     drift.Value(row.sellingPrice),
              stockQuantity:    drift.Value(row.stockQuantity),
              minimumStockLevel:drift.Value(row.minimumStockLevel),
              isActive:         drift.Value(row.isActive),
            ),
          );
          imported++;
        }
      } catch (e) {
        errors.add('${row.name}: $e');
      }
    }

    return ImportResult(imported: imported, updated: updated, skipped: skipped, errors: errors);
  }

  static String _timestamp(DateTime now) {
    final mo  = now.month.toString().padLeft(2, '0');
    final dy  = now.day.toString().padLeft(2, '0');
    final hh  = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return '${now.year}-$mo-$dy\_$hh-$min';
  }
}
