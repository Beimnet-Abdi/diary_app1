import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted glass circle back control for use over light or dark backgrounds.
class GlassBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;

  const GlassBackButton({
    super.key,
    this.onPressed,
    this.icon = Icons.arrow_back_ios_new,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed ?? () => Navigator.maybePop(context),
        customBorder: const CircleBorder(),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF2D2D2D)),
            ),
          ),
        ),
      ),
    );
  }
}
