import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? borderColor;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const AppCard({
    Key? key,
    required this.child,
    this.borderRadius = 12.0, // Sleeker border radius for native feel
    this.borderColor,
    this.color,
    this.padding,
    this.margin,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16), // Tighter, cleaner padding
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1.0, // Cleaner native-like 1px border
        ),
      ),
      child: child,
    );
  }
}
