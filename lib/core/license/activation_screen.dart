/// activation_screen.dart — Full-screen activation UI shown when no valid
/// license is found. Matches the app's "Midnight Commerce" dark theme.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'license_service.dart';
import 'license_crypto.dart';

class ActivationScreen extends StatefulWidget {
  final String          machineId;
  final LicenseStatus   status;
  final VoidCallback    onActivated;

  const ActivationScreen({
    super.key,
    required this.machineId,
    required this.status,
    required this.onActivated,
  });

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _keyController = TextEditingController();
  final _formKey       = GlobalKey<FormState>();
  bool   _loading      = false;
  String _statusMsg    = '';
  bool   _statusOk     = false;
  bool   _obscure      = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _setStatus(String msg, {bool ok = false}) =>
      setState(() { _statusMsg = msg; _statusOk = ok; });

  Future<void> _copyMid() async {
    await Clipboard.setData(ClipboardData(text: widget.machineId));
    _setStatus('✓ Machine ID copied to clipboard.', ok: true);
  }

  Future<void> _activate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    _setStatus('');

    final ok = await LicenseService.activate(
        widget.machineId, _keyController.text.trim());

    setState(() => _loading = false);
    if (ok) {
      _setStatus('✓ Activation successful!  Opening…', ok: true);
      await Future.delayed(const Duration(milliseconds: 700));
      widget.onActivated();
    } else {
      _setStatus('✗ Invalid key — please check and try again.');
      _keyController.clear();
    }
  }

  // ── A descriptive banner per status ──────────────────────────────────────

  Widget _buildBanner() {
    String msg;
    Color  col;
    IconData ico;

    switch (widget.status) {
      case LicenseStatus.tampered:
        msg = 'License file is invalid or has been tampered with.';
        col = AppTheme.accentOrange;
        ico = Icons.warning_amber_rounded;
      case LicenseStatus.expired:
        msg = 'Your license has expired. Contact your vendor to renew.';
        col = AppTheme.accentRed;
        ico = Icons.timer_off_rounded;
      default:
        msg = 'No license found for this machine. Enter your Activation Key below.';
        col = AppTheme.textSecondary;
        ico = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:        col.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: col.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(ico, color: col, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
              style: TextStyle(color: col, fontSize: 13))),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Stack(children: [
          // Glowing orb background
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _OrbPainter(),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color:  AppTheme.bgCard.withAlpha(220),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.borderDefault),
                      ),
                      padding: const EdgeInsets.all(36),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Icon
                            Center(
                              child: Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.accent],
                                    begin: Alignment.topLeft,
                                    end:   Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withAlpha(90),
                                      blurRadius: 24, spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.lock_rounded,
                                    color: Colors.white, size: 30),
                              ),
                            ),
                            const SizedBox(height: 18),

                            const Text('Activation Required',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 22, fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('POS Africa — License Verification',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 24),

                            _buildBanner(),

                            // Machine ID display
                            const Text('Your Machine ID:',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _copyMid,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color:  AppTheme.bgSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.primary.withAlpha(80)),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      widget.machineId,
                                      style: const TextStyle(
                                        color:      AppTheme.primary,
                                        fontSize:   20,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Courier New',
                                        letterSpacing: 4,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Tooltip(
                                      message: 'Copy to clipboard',
                                      child: Icon(Icons.copy_rounded,
                                          color: AppTheme.textMuted, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Send this ID to your vendor to get an Activation Key.',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 20),

                            // Activation Key input
                            const Text('Activation Key:',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _keyController,
                              obscureText: _obscure,
                              style: const TextStyle(
                                color:      AppTheme.textPrimary,
                                fontFamily: 'Courier New',
                                fontSize:   16,
                                letterSpacing: 2,
                              ),
                              decoration: InputDecoration(
                                hintText: '${kActivationKeyLength}-character key',
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                      size: 18),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              onFieldSubmitted: (_) => _activate(),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter the activation key';
                                }
                                if (v.trim().length != kActivationKeyLength) {
                                  return 'Key must be exactly $kActivationKeyLength characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Status message
                            if (_statusMsg.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  _statusMsg,
                                  style: TextStyle(
                                    color: _statusOk
                                        ? AppTheme.accentGreen
                                        : AppTheme.accentRed,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            // Activate button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _activate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:       Colors.white),
                                      )
                                    : const Text('Activate',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Glowing orb background (same as login screen) ───────────────────────────
class _OrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void orb(Offset center, double radius, Color color, double opacity) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withAlpha((opacity * 255).toInt()), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    orb(Offset(size.width * 0.15, size.height * 0.25), 260,
        AppTheme.primary, 0.20);
    orb(Offset(size.width * 0.85, size.height * 0.70), 200,
        AppTheme.accent, 0.15);
    orb(Offset(size.width * 0.55, size.height * 0.10), 150,
        AppTheme.accentViolet, 0.12);
  }

  @override
  bool shouldRepaint(_) => false;
}
