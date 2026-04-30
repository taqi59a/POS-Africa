import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey             = GlobalKey<FormState>();
  bool _obscurePassword      = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(_usernameController.text.trim(), _passwordController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          // ── Glowing orbs background ──────────────────────────────────────
          CustomPaint(size: MediaQuery.of(context).size, painter: _OrbPainter()),

          // ── Center card ─────────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard.withAlpha(220),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.borderDefault, width: 1),
                      ),
                      padding: const EdgeInsets.all(40),
                      child: BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthFailure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(children: [
                                  const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(state.error)),
                                ]),
                                backgroundColor: const Color(0xFF1E1520),
                              ),
                            );
                          }
                        },
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          return Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo area
                                Center(
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.primary, AppTheme.accent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary.withAlpha(100),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.point_of_sale_rounded,
                                        color: Colors.white, size: 36),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Brand name
                                const Text(
                                  'POS Africa',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Point of Sale System',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                ),
                                const SizedBox(height: 36),

                                // Username
                                TextFormField(
                                  controller: _usernameController,
                                  enabled: !isLoading,
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person_outline_rounded),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Username is required' : null,
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  enabled: !isLoading,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined),
                                      onPressed: () =>
                                          setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _onLogin(),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Password is required' : null,
                                ),
                                const SizedBox(height: 28),

                                // Sign in button
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _onLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 22, height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white))
                                        : const Text('Sign In',
                                            style: TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Version hint
                                const Text(
                                  'v1.0.0  ·  Default: admin / master',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glowing orb background painter ─────────────────────────────────────────
class _OrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void orb(Offset center, double radius, Color color, double opacity) {
      final paint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
      paint.shader = RadialGradient(
        colors: [color.withAlpha((opacity * 255).round()), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    orb(Offset(size.width * 0.15, size.height * 0.25), size.height * 0.45,
        AppTheme.primary, 0.35);
    orb(Offset(size.width * 0.85, size.height * 0.70), size.height * 0.40,
        AppTheme.accent, 0.25);
    orb(Offset(size.width * 0.90, size.height * 0.10), size.height * 0.30,
        AppTheme.accentViolet, 0.20);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => false;
}
