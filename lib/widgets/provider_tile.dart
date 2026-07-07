import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/connected_account.dart';

/// A selectable photo-source row on the Connect screen. Turns mint-green with a
/// check when linked; "coming soon" sources are shown locked.
class ProviderTile extends StatelessWidget {
  const ProviderTile({
    super.key,
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final ConnectedAccount account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = account.comingSoon;
    return Opacity(
      opacity: disabled ? 0.7 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0FBF9) : Colors.white,
            border: Border.all(
              color: selected ? BrandColors.mint : BrandColors.line,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(BrandRadius.button),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Color(account.brandColor),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(account.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    Text(account.subtitle,
                        style: const TextStyle(fontSize: 12.5, color: BrandColors.muted)),
                  ],
                ),
              ),
              if (disabled)
                const Text('SOON',
                    style: TextStyle(
                        fontSize: 11, color: BrandColors.muted, fontWeight: FontWeight.w700))
              else
                _Toggle(on: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? BrandColors.mint : Colors.transparent,
        border: Border.all(color: on ? BrandColors.mint : BrandColors.line, width: 2),
      ),
      child: on
          ? const Icon(Icons.check, size: 15, color: Colors.white)
          : const SizedBox.shrink(),
    );
  }
}
