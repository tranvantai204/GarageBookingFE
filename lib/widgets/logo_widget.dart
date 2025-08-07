import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool animated;
  final Color? color;

  const LogoWidget({
    super.key,
    this.size = 100,
    this.animated = false, // Tắt animation để tối ưu
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade600, Colors.blue.shade800],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.directions_bus, size: size * 0.4, color: Colors.white),
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
        LogoWidget(size: size, animated: false),
        const SizedBox(height: 16),
        Text(
          text,
          style: TextStyle(
            fontSize: size * 0.15,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
