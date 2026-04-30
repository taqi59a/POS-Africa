/// license_guard.dart — Top-level widget that gates the entire app behind
/// the license check. Used as `home:` inside MaterialApp.
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'activation_screen.dart';
import 'license_service.dart';

class LicenseGuard extends StatefulWidget {
  /// The widget shown once a valid license is confirmed (normally AuthWrapper).
  final Widget child;

  const LicenseGuard({super.key, required this.child});

  @override
  State<LicenseGuard> createState() => _LicenseGuardState();
}

class _LicenseGuardState extends State<LicenseGuard> {
  late Future<LicenseCheckResult> _checkFuture;

  @override
  void initState() {
    super.initState();
    _checkFuture = LicenseService.check();
  }

  void _recheck() => setState(() => _checkFuture = LicenseService.check());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LicenseCheckResult>(
      future: _checkFuture,
      builder: (context, snap) {
        // ── Still loading hardware IDs ────────────────────────────────────
        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: AppTheme.bgDeep,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                        begin: Alignment.topLeft,
                        end:   Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.point_of_sale_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                        color: AppTheme.primary, strokeWidth: 2),
                  ),
                  const SizedBox(height: 12),
                  const Text('Verifying license…',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        final result = snap.data!;

        // ── Licensed ──────────────────────────────────────────────────────
        if (result.isLicensed) return widget.child;

        // ── Expired ───────────────────────────────────────────────────────
        if (result.status == LicenseStatus.expired) {
          return ActivationScreen(
            machineId:   result.machineId,
            status:      LicenseStatus.expired,
            onActivated: _recheck,
          );
        }

        // ── Not licensed / tampered ────────────────────────────────────────
        return ActivationScreen(
          machineId:   result.machineId,
          status:      result.status,
          onActivated: _recheck,
        );
      },
    );
  }
}
