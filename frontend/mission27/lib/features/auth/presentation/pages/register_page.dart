import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authStateProvider.notifier).register(
      email: _emailCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _fullNameCtrl.text.trim(),
    );
    if (!mounted) return;
    final authState = ref.read(authStateProvider).value;
    if (authState?.errorMessage != null) {
      context.showSnackBar(authState!.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text('Create Account', style: AppTypography.headlineMedium)
                    .animate()
                    .fadeIn(duration: 600.ms),
                const SizedBox(height: 6),
                Text(
                  'Start your growth journey.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 36),
                _field(_fullNameCtrl, 'Full Name', 'Masab Arain', delay: 200, validator: (v) {
                  if (v == null || v.length < 2) return 'Enter your full name';
                  return null;
                }),
                const SizedBox(height: 16),
                _field(_usernameCtrl, 'Username', 'masab27', delay: 250, validator: (v) {
                  if (v == null || v.length < 3) return 'At least 3 characters';
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) return 'Letters, numbers, _ only';
                  return null;
                }),
                const SizedBox(height: 16),
                _field(_emailCtrl, 'Email', 'you@example.com', delay: 300,
                    keyboardType: TextInputType.emailAddress, validator: (v) {
                  if (v == null || !v.contains('@')) return 'Enter a valid email';
                  return null;
                }),
                const SizedBox(height: 16),
                _field(_passwordCtrl, 'Password', '••••••••', delay: 350,
                    isPassword: true, validator: (v) {
                  if (v == null || v.length < 8) return 'At least 8 characters';
                  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one digit';
                  return null;
                }),
                const SizedBox(height: 32),
                M27Button(
                  label: 'Create Account',
                  onPressed: _submit,
                  isLoading: isLoading,
                  isFullWidth: true,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    required int delay,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return AuthFormField(
      label: label,
      hint: hint,
      controller: ctrl,
      isPassword: isPassword,
      keyboardType: keyboardType,
      validator: validator,
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 500.ms).slideY(begin: 0.1);
  }
}
