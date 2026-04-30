/// license_store.dart — Versioned JSON license file I/O.
///
/// Schema version history:
///   v1 (current): machine_id, activation_key, license_type, features,
///                 issued_to, activated_at, expires_at, max_users, notes
///
/// Adding new fields in a future version:
///   1. Add a getter to [LicenseData] with a safe default.
///   2. Add the field to [_buildRecord].
///   3. Add a migration branch in [_migrate] and bump [_schemaVersion].
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const int    _schemaVersion   = 1;
const String _licenseFileName = 'license.dat';

// ── Path ─────────────────────────────────────────────────────────────────────

Future<String> _licensePath() async {
  // Try the directory next to the EXE first (portable builds).
  // If it is not writable (e.g. Program Files), fall back to AppData.
  final exeDir  = File(Platform.resolvedExecutable).parent;
  final exeFile = File(p.join(exeDir.path, _licenseFileName));

  if (await exeFile.exists()) return exeFile.path; // already placed there

  try {
    final test = File(p.join(exeDir.path, '.lic_test'));
    await test.writeAsString('w');
    await test.delete();
    return exeFile.path; // writable → portable layout
  } catch (_) {
    // Installed build → use the per-user app-support directory (%APPDATA%)
    final appDir = await getApplicationSupportDirectory();
    await appDir.create(recursive: true);
    return p.join(appDir.path, _licenseFileName);
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class LicenseData {
  final int           schemaVersion;
  final String        machineId;
  final String        activationKey;
  final String        licenseType;
  final List<String>  features;
  final String        issuedTo;
  final String        activatedAt;
  final String?       expiresAt;
  final int           maxUsers;
  final String        notes;
  final Map<String, dynamic> raw;

  const LicenseData({
    required this.schemaVersion,
    required this.machineId,
    required this.activationKey,
    required this.licenseType,
    required this.features,
    required this.issuedTo,
    required this.activatedAt,
    this.expiresAt,
    required this.maxUsers,
    required this.notes,
    required this.raw,
  });

  factory LicenseData.fromJson(Map<String, dynamic> j) => LicenseData(
    schemaVersion: j['version']  as int?    ?? 1,
    machineId:    ((j['machine_id']     as String?) ?? '').toUpperCase(),
    activationKey:((j['activation_key'] as String?) ?? '').toUpperCase(),
    licenseType:   j['license_type'] as String? ?? 'full',
    features:      List<String>.from(j['features'] as List? ?? ['all']),
    issuedTo:      j['issued_to']    as String? ?? '',
    activatedAt:   j['activated_at'] as String? ?? '',
    expiresAt:     j['expires_at']   as String?,
    maxUsers:      j['max_users']    as int?    ?? -1,
    notes:         j['notes']        as String? ?? '',
    raw:           j,
  );

  bool get isExpired {
    if (expiresAt == null) return false;
    try {
      return DateTime.now().isAfter(DateTime.parse(expiresAt!));
    } catch (_) {
      return false;
    }
  }

  bool hasFeature(String f) => features.contains('all') || features.contains(f);
}

// ── Migration ─────────────────────────────────────────────────────────────────

Map<String, dynamic> _migrate(Map<String, dynamic> data) {
  final version = data['version'] as int? ?? 1;
  // Example future migration:
  // if (version < 2) {
  //   data.putIfAbsent('subscription_id', () => null);
  //   data['version'] = 2;
  // }
  return data;
}

// ── I/O ───────────────────────────────────────────────────────────────────────

Future<LicenseData?> loadLicense() async {
  try {
    final path = await _licensePath();
    final file = File(path);
    if (!file.existsSync()) return null;
    final raw  = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return LicenseData.fromJson(_migrate(raw));
  } catch (_) {
    return null;
  }
}

Future<void> saveLicense({
  required String machineId,
  required String activationKey,
}) async {
  final path   = await _licensePath();
  final record = _buildRecord(machineId: machineId, activationKey: activationKey);
  await File(path).writeAsString(
    const JsonEncoder.withIndent('  ').convert(record));
}

Map<String, dynamic> _buildRecord({
  required String machineId,
  required String activationKey,
}) =>
    {
      'version':        _schemaVersion,
      'schema':         'pos_license_v$_schemaVersion',
      'machine_id':     machineId.trim().toUpperCase(),
      'activation_key': activationKey.trim().toUpperCase(),
      'license_type':   'full',
      'features':       ['all'],
      'issued_to':      '',
      'max_users':      -1,
      'activated_at':   DateTime.now().toUtc().toIso8601String(),
      'expires_at':     null,
      'notes':          '',
    };
