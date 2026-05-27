import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';

/// Sebuah widget premium pembungkus shimmer skeleton loader
/// menggunakan pustaka flutter_animate yang responsif, modern, dan sangat hemat performa.
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    Key? key,
    required this.child,
    this.isLoading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withOpacity(0.55),
          angle: 45,
        );
  }
}

/// Helper instan untuk membuat berbagai bentuk skeleton placeholder
/// yang berdenyut shimmer secara elegan.
class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? color;

  const ShimmerSkeleton({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.color,
  }) : super(key: key);

  /// Skeleton berbentuk baris teks minimalis
  factory ShimmerSkeleton.text({
    Key? key,
    required double width,
    double height = 14,
    double borderRadius = 4,
  }) {
    return ShimmerSkeleton(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  /// Skeleton berbentuk lingkaran (biasanya untuk avatar atau ikon)
  factory ShimmerSkeleton.circle({
    Key? key,
    required double size,
  }) {
    return ShimmerSkeleton(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  /// Skeleton berbentuk kartu/kontainer rounded besar
  factory ShimmerSkeleton.card({
    Key? key,
    double width = double.infinity,
    double height = 80,
    double borderRadius = 12,
  }) {
    return ShimmerSkeleton(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? AppColors.surfaceAlt.withOpacity(0.6),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
