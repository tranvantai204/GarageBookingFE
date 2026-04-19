import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SimpleBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const SimpleBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: colors != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors!,
              )
            : AppTheme.backgroundGradient,
      ),
      child: child,
    );
  }
}

class SimpleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const SimpleCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        color: AppTheme.surface,
        boxShadow: AppTheme.shadowCard,
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
