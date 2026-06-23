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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authStateProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _Header().animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
                const SizedBox(height: 48),
                AuthFormField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
                AuthFormField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordCtrl,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _submit,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1),
                const SizedBox(height: 32),
                M27Button(
                  label: 'Sign In',
                  onPressed: _submit,
                  isLoading: isLoading,
                  isFullWidth: true,
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.register),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.gradientPrimary.createShader(bounds),
          child: Text('Mission 27', style: AppTypography.headlineLarge),
        ),
        const SizedBox(height: 8),
        Text(
          'Your personal growth operating system.',
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
