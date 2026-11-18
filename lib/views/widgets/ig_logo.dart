import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class IgLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showText;

  const IgLogo({
    super.key,
    this.iconSize = 28,
    this.fontSize = 26,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize + 10,
          height: iconSize + 10,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(iconSize * .38),
          ),
          child: Icon(Icons.camera_alt_outlined,
              size: iconSize, color: Colors.white),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'Instagram',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}
