/// hardware_fingerprint.dart — Windows hardware ID collection.
///
/// Priority chain for CPU ID:
///   1. wmic cpu get ProcessorId          (Windows 7 – 11 22H2)
///   2. PowerShell Get-WmiObject          (Windows 11 24H2+ — wmic removed)
///   3. hostname fallback
///
/// Same fallback chain for motherboard serial.
/// On non-Windows platforms returns a hostname-based string (future-proof).
library;

import 'dart:io';

const _junkValues = {
  '',
  'to be filled by o.e.m.',
  'none',
  'n/a',
  'default string',
  'not applicable',
  'system serial number',
  'base board serial number',
  '0000000000000000',
};

bool _isJunk(String v) => _junkValues.contains(v.toLowerCase().trim());

Future<String> _run(String exe, List<String> args) async {
  try {
    final r = await Process.run(exe, args, runInShell: false);
    return r.stdout.toString();
  } catch (_) {
    return '';
  }
}

/// Extract the first non-header line from wmic tabular output.
String _firstDataLine(String out) {
  final lines = out
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  return lines.length > 1 ? lines[1] : '';
}

Future<String> getCpuId() async {
  if (!Platform.isWindows) return Platform.localHostname;

  // 1. wmic
  var v = _firstDataLine(
      await _run('wmic', ['cpu', 'get', 'ProcessorId']));
  if (v.isNotEmpty && !_isJunk(v)) return v;

  // 2. PowerShell fallback
  v = (await _run('powershell', [
    '-NonInteractive', '-NoProfile', '-Command',
    '(Get-WmiObject -Class Win32_Processor).ProcessorId',
  ])).trim();
  if (v.isNotEmpty && !_isJunk(v)) return v;

  return Platform.localHostname;
}

Future<String> getBoardSerial() async {
  if (!Platform.isWindows) return Platform.localHostname;

  // 1. wmic baseboard
  var v = _firstDataLine(
      await _run('wmic', ['baseboard', 'get', 'SerialNumber']));
  if (v.isNotEmpty && !_isJunk(v)) return v;

  // 2. PowerShell baseboard
  v = (await _run('powershell', [
    '-NonInteractive', '-NoProfile', '-Command',
    '(Get-WmiObject -Class Win32_BaseBoard).SerialNumber',
  ])).trim();
  if (v.isNotEmpty && !_isJunk(v)) return v;

  // 3. System UUID
  v = (await _run('powershell', [
    '-NonInteractive', '-NoProfile', '-Command',
    '(Get-WmiObject -Class Win32_ComputerSystemProduct).UUID',
  ])).trim();
  if (v.isNotEmpty && !_isJunk(v)) return v;

  return Platform.localHostname;
}
