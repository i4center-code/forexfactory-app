import 'package:flutter/material.dart';

/// نشان شدت خبر؛ رنگ‌ها همان نگاشت قبلی: بالا قرمز، متوسط نارنجی، پایین زرد، تعطیل خاکستری.
class ImpactBadge extends StatelessWidget {
  const ImpactBadge({super.key, required this.impact, this.size = 24});
  final String impact;
  final double size;

  static (Color, String) style(String impact) {
    switch (impact.toLowerCase()) {
      case 'high':
        return (Colors.red.shade600, 'بالا');
      case 'medium':
        return (Colors.orange.shade600, 'متوسط');
      case 'low':
        return (Colors.amber.shade400, 'پایین');
      case 'holiday':
        return (Colors.grey.shade500, 'تعطیل');
      default:
        return (Colors.blueGrey.shade300, impact.isEmpty ? '-' : impact);
    }
  }

  static int level(String impact) {
    switch (impact.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = style(impact);
    final lvl = level(impact);
    final isHoliday = impact.toLowerCase() == 'holiday';
    return Semantics(
      label: label,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(size * 0.34)),
        child: isHoliday
            ? Icon(Icons.flag_rounded, size: size * 0.62, color: color)
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 1; i <= 3; i++) ...[
                    if (i > 1) SizedBox(width: size * 0.07),
                    Container(
                      width: size * 0.16,
                      height: size * (0.22 + 0.16 * i),
                      decoration: BoxDecoration(
                        color: i <= lvl ? color : color.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
