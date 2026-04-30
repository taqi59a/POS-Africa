import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey                   = GlobalKey<FormState>();
  bool _obscureNew    = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
          AuthChangePasswordRequested(_passwordController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          CustomPaint(size: MediaQuery.of(context).size, painter: _OrbPainter()),
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
                        border: Border.all(color: AppTheme.borderDefault),
                      ),
                      padding: const EdgeInsets.all(40),
                      child: BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthFailure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.error),
                                  backgroundColor: const Color(0xFF1E1520)),
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
                                Center(
                                  child: Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF8C42), Color(0xFFFF3D57)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [BoxShadow(
                                        color: const Color(0xFFFF8C42).withAlpha(100),
                                        blurRadius: 24, spreadRadius: 2,
                                      )],
                                    ),
                                    child: const Icon(Icons.security_rounded,
                                        color: Colors.white, size: 36),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text('Update Password',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textPrimary,
                                      fontSize: 24, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Your account requires a password change before you can access the system.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13,
                                      height: 1.5),
                                ),
                                const SizedBox(height: 32),

                                TextFormField(
                                  controller: _passwordController,
                                  enabled: !isLoading,
                                  obscureText: _obscureNew,
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureNew
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined),
                                      onPressed: () =>
                                          setState(() => _obscureNew = !_obscureNew),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    if (v.length < 6) return 'Min 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _confirmPasswordController,
                                  enabled: !isLoading,
                                  obscureText: _obscureConfirm,
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined),
                                      onPressed: () => setState(
                                          () => _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _onSubmit(),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    if (v != _passwordController.text)
                                      return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 28),

                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _onSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentOrange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(width: 22, height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white))
                                        : const Text('Set New Password',
                                            style: TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.w600)),
                                  ),
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
    orb(Offset(size.width * 0.2, size.height * 0.2), size.height * 0.4,
        AppTheme.accentOrange, 0.3);
    orb(Offset(size.width * 0.8, size.height * 0.8), size.height * 0.35,
        AppTheme.accentRed, 0.2);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => false;
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthChangePasswordRequested(_passwordController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('Mandatory Password Change'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.error), backgroundColor: Colors.red),
                      );
                    }
                  },
                  builder: (context, state) {
                    return Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.security, size: 64, color: Colors.orangeAccent),
                          const SizedBox(height: 16),
                          Text(
                            'Update Your Password',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'For your security, you must change your default password before accessing the system.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter new password';
                              if (value.length < 8) return 'Password must be at least 8 characters';
                              if (!value.contains(RegExp(r'[0-9]'))) return 'Must contain at least one number';
                              return null;
                            },
                            enabled: state is! AuthLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                            enabled: state is! AuthLoading,
                            onFieldSubmitted: (_) => _onSubmit(),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: state is AuthLoading ? null : _onSubmit,
                            child: state is AuthLoading
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save Password', style: TextStyle(fontSize: 16)),
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
    );
  }
}
