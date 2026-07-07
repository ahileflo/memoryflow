import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Small uppercase coral "eyebrow" above headings (e.g. "AI MEMORY CONCIERGE").
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = BrandColors.coral});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.4,
        color: color,
      ),
    );
  }
}

/// Muted uppercase section label (e.g. "SMART ALBUMS").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: BrandColors.muted,
      ),
    );
  }
}

/// Rounded pill chip used throughout (e.g. "✨ Auto-created").
class BrandChip extends StatelessWidget {
  const BrandChip(
    this.label, {
    super.key,
    this.background = BrandColors.panel,
    this.foreground = BrandColors.violetDark,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(BrandRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

/// Circular gradient avatar with the user's initial.
class BrandAvatar extends StatelessWidget {
  const BrandAvatar({super.key, required this.initial, this.size = 42, this.onTap});
  final String initial;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BrandColors.violet, BrandColors.coral],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.4),
        ),
      ),
    );
  }
}
