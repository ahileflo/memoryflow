import 'package:flutter/material.dart';

import '../core/theme.dart';

enum BrandButtonStyle { primary, dark, ghost, transparent }

/// The app's primary action button. Coral is the action color (primary style).
class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = BrandButtonStyle.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final BrandButtonStyle style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    late final Color bg;
    late final Color fg;
    List<BoxShadow>? shadow;

    switch (style) {
      case BrandButtonStyle.primary:
        bg = BrandColors.coral;
        fg = Colors.white;
        shadow = softShadow(color: BrandColors.coral, opacity: 0.40);
      case BrandButtonStyle.dark:
        bg = BrandColors.indigo;
        fg = Colors.white;
      case BrandButtonStyle.ghost:
        bg = BrandColors.panel;
        fg = BrandColors.ink;
      case BrandButtonStyle.transparent:
        bg = Colors.transparent;
        fg = const Color(0xFF9A95B5);
    }

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(BrandRadius.button),
          boxShadow: enabled ? shadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(BrandRadius.button),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
