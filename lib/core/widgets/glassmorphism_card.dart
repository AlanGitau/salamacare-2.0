import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';

/// A glassmorphism card widget — kept for legacy compatibility.
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<Color>? gradientColors;
  final double opacity;
  final double blurSigma;
  final Border? border;
  final VoidCallback? onTap;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 8,
    this.gradientColors,
    this.opacity = 0.7,
    this.blurSigma = 10,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradientColors = [
      Colors.white.withValues(alpha: opacity),
      Colors.white.withValues(alpha: opacity * 0.5),
    ];

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ?? defaultGradientColors,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Flat admin-style card — white surface, borderLight border, 8px radius, no shadow.
/// Matches the TailAdmin / Linear design system used in the admin panel.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Gradient? gradient; // ignored — kept for call-site compatibility
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow; // ignored — no shadows in admin style

  const PremiumCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 8,
    this.color,
    this.gradient,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? adminBgSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: adminBorderLight),
        // NO boxShadow — the light bgCanvas background replaces shadows
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}
