/// license_crypto.dart — Pure hashing logic (no Flutter dependency).
///
/// MUST stay in sync with tools/license_system/shared_crypto.py —
/// same salt segments, same algorithm, same lengths.
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';

// ── Secret Salt (split at runtime to hinder static binary analysis) ─────────
// Change ALL four segments before distributing. Must match shared_crypto.py.
const _sA = '9Xk#2mPq';
const _sB = '!7vR\$nL4';
const _sC = 'wZ@5jBt8';
const _sD = 'Ue6*Gy3F';
String get _salt => _sA + _sB + _sC + _sD;

/// Length of the Machine ID shown to the end user (hex chars).
const int kMachineIdLength = 8;

/// Length of the Activation Key the user must enter (hex chars).
const int kActivationKeyLength = 12;

/// Produce an 8-char uppercase hex fingerprint from two hardware strings.
/// The `|` separator prevents prefix-collision attacks.
String deriveMachineId(String cpuId, String boardSerial) {
  final raw    = utf8.encode('${cpuId.trim()}|${boardSerial.trim()}');
  final digest = sha256.convert(raw);
  return digest.toString().substring(0, kMachineIdLength).toUpperCase();
}

/// Generate the 12-char uppercase activation key for the given Machine ID.
/// Formula: SHA-256( UPPER(machineId) + SECRET_SALT )[:12].upper()
String generateActivationKey(String machineId) {
  final payload = utf8.encode(machineId.trim().toUpperCase() + _salt);
  final digest  = sha256.convert(payload);
  return digest.toString().substring(0, kActivationKeyLength).toUpperCase();
}

/// Return true when [key] was generated for [machineId].
bool verifyActivationKey(String machineId, String key) =>
    generateActivationKey(machineId) == key.trim().toUpperCase();
