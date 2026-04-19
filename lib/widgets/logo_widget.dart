import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool animated;
  final Color? color;

  const LogoWidget({
    super.key,
    this.size = 100,
    this.animated = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        Icons.directions_bus_rounded,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}

class AnimatedLogo extends StatelessWidget {
  final double size;
  final String text;

  const AnimatedLogo({super.key, this.size = 120, this.text = 'GarageBooking'});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: AppTheme.shadowPrimary,
          ),
          child: Icon(
            Icons.directions_bus_rounded,
            size: size * 0.55,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }
}
