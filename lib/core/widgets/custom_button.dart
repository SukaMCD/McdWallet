import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final bool isOutlined;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.isOutlined = false,
    this.icon,
    this.color,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;
    final contentColor = textColor ?? (isOutlined ? AppColors.textPrimary : Colors.white);

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(contentColor),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: contentColor),
          if (text.isNotEmpty) const SizedBox(width: 10),
        ],
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(
              color: contentColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
      ],
    );

    final ButtonStyle style;
    final Widget button;

    if (isOutlined) {
      style = OutlinedButton.styleFrom(
        foregroundColor: contentColor,
        side: const BorderSide(color: AppColors.border, width: 1.0),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      );
      button = OutlinedButton(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              },
        style: style,
        child: child,
      );
    } else {
      style = ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        foregroundColor: contentColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
      button = ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              },
        style: style,
        child: child,
      );
    }

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
