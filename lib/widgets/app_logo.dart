import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1e3a8a), // Blue 900
                Color(0xFF3b82f6), // Blue 500
                Color(0xFF06b6d4), // Cyan 500
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Mountain peaks (Nepal representation)
              Positioned(
                top: size * 0.15,
                child: Icon(
                  Icons.terrain,
                  color: Colors.red.withValues(alpha: 0.8),
                  size: size * 0.4,
                ),
              ),
              // Kangaroo silhouette (Australia representation)
              Positioned(
                bottom: size * 0.15,
                child: Icon(
                  Icons.pets,
                  color: Colors.grey[800]!.withValues(alpha: 0.9),
                  size: size * 0.35,
                ),
              ),
              // Helping hand
              Positioned(
                child: Icon(
                  Icons.waving_hand,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: size * 0.25,
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'NEPAL HELP',
            style: TextStyle(
              fontSize: size * 0.18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'AUSTRALIA',
            style: TextStyle(
              fontSize: size * 0.12,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}

// Alternative SVG-based logo widget
class AppLogoSvg extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogoSvg({
    super.key,
    this.size = 100,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            cacheWidth: (size * MediaQuery.of(context).devicePixelRatio).toInt(),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'HamroOZ',
            style: TextStyle(
              fontSize: size * 0.18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}