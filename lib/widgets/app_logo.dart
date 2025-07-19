import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? size;
  final Color? fallbackColor;
  final bool showTitle;
  final String? customTitle;

  const AppLogo({
    super.key,
    this.size = 80,
    this.fallbackColor = Colors.blue,
    this.showTitle = false,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: size,
          width: size,
          child: Image.asset(
            'assets/images/logo.png',
            height: size,
            width: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image doesn't exist
              return Icon(
                Icons.business,
                size: size! * 0.8,
                color: fallbackColor,
              );
            },
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 16),
          Text(
            customTitle ?? 'Workforce Management',
            style: TextStyle(
              fontSize: size! * 0.3,
              fontWeight: FontWeight.bold,
              color: fallbackColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class AppLogoSmall extends StatelessWidget {
  final double size;
  final Color? fallbackColor;

  const AppLogoSmall({
    super.key,
    this.size = 32,
    this.fallbackColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      child: Image.asset(
        'assets/images/logo.png',
        height: size,
        width: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image doesn't exist
          return Icon(Icons.business, size: size * 0.8, color: fallbackColor);
        },
      ),
    );
  }
}
