import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum M27ButtonVariant { primary, secondary, outline, ghost, danger }

class M27Button extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final M27ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? height;

  const M27Button({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = M27ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig();

    Widget child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: config.foreground,
            ),
          )
        else ...[
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 18, color: config.foreground),
            const SizedBox(width: 8),
          ],
          Text(label, style: AppTypography.labelLarge.copyWith(color: config.foreground)),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, size: 18, color: config.foreground),
          ],
        ],
      ],
    );

    final button = Material(
      color: config.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (isLoading || onPressed == null) ? null : onPressed,
        child: Container(
          height: height ?? 50,
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: config.border,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  _ButtonConfig _resolveConfig() {
    switch (variant) {
      case M27ButtonVariant.primary:
        return _ButtonConfig(
          background: AppColors.primary,
          foreground: AppColors.textPrimary,
        );
      case M27ButtonVariant.secondary:
        return _ButtonConfig(
          background: AppColors.secondary,
          foreground: AppColors.background,
        );
      case M27ButtonVariant.outline:
        return _ButtonConfig(
          background: Colors.transparent,
          foreground: AppColors.primary,
          border: Border.all(color: AppColors.primary, width: 1.5),
        );
      case M27ButtonVariant.ghost:
        return _ButtonConfig(
          background: AppColors.surfaceVariant,
          foreground: AppColors.textPrimary,
        );
      case M27ButtonVariant.danger:
        return _ButtonConfig(
          background: AppColors.error,
          foreground: AppColors.textPrimary,
        );
    }
  }
}

class _ButtonConfig {
  final Color background;
  final Color foreground;
  final Border? border;

  const _ButtonConfig({
    required this.background,
    required this.foreground,
    this.border,
  });
}
