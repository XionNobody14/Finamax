import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Píldora interactiva de recomendación accionable
class AITipPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const AITipPill({
    super.key,
    required this.text,
    this.icon = Icons.eco_outlined,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.forestGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: activeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activeColor.withOpacity(0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: activeColor, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
