/// license_service.dart — Combines hardware fingerprinting, crypto, and storage
/// into a single async API used by [LicenseGuard].
library;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'hardware_fingerprint.dart';
import 'license_crypto.dart';
import 'license_store.dart';

enum LicenseStatus {
  /// Valid license confirmed for this machine.
  licensed,
  /// No license file found, or machine ID does not match.
  notLicensed,
  /// License file exists but is corrupt / tampered with.
  tampered,
  /// License was valid but has passed its expiry date.
  expired,
}

class LicenseCheckResult {
  final LicenseStatus  status;
  final String         machineId;
  final LicenseData?   data;

  const LicenseCheckResult({
    required this.status,
    required this.machineId,
    this.data,
  });

  bool get isLicensed => status == LicenseStatus.licensed;
}

class LicenseService {
  /// Check the current machine's license status.
  ///
  /// In debug / profile mode the check is skipped and the app opens freely,
  /// so developers never need to activate their own machines.
  static Future<LicenseCheckResult> check() async {
    // ── Dev / profile bypass ─────────────────────────────────────────────
    if (!kReleaseMode) {
      return const LicenseCheckResult(
        status:    LicenseStatus.licensed,
        machineId: 'DEV_MODE',
      );
    }

    // ── Collect hardware fingerprint ─────────────────────────────────────
    final cpuId       = await getCpuId();
    final boardSerial = await getBoardSerial();
    final machineId   = deriveMachineId(cpuId, boardSerial);

    // ── Read license file ────────────────────────────────────────────────
    final lic = await loadLicense();
    if (lic == null) {
      return LicenseCheckResult(
          status: LicenseStatus.notLicensed, machineId: machineId);
    }

    // ── Verify key integrity ─────────────────────────────────────────────
    if (!verifyActivationKey(lic.machineId, lic.activationKey)) {
      return LicenseCheckResult(
          status: LicenseStatus.tampered, machineId: machineId);
    }

    // ── Verify this machine ──────────────────────────────────────────────
    if (lic.machineId != machineId) {
      return LicenseCheckResult(
          status: LicenseStatus.notLicensed, machineId: machineId);
    }

    // ── Expiry check ─────────────────────────────────────────────────────
    if (lic.isExpired) {
      return LicenseCheckResult(
          status: LicenseStatus.expired, machineId: machineId, data: lic);
    }

    return LicenseCheckResult(
        status: LicenseStatus.licensed, machineId: machineId, data: lic);
  }

  /// Validate [key] against [machineId] and write license.dat if correct.
  /// Returns true on success.
  static Future<bool> activate(String machineId, String key) async {
    if (!verifyActivationKey(machineId, key)) return false;
    await saveLicense(machineId: machineId, activationKey: key);
    return true;
  }
}
