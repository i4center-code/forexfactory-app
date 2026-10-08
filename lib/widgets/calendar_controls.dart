import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import 'event_tile.dart';
import 'impact_badge.dart';

/// نوار روزهای هفتهٔ شمسی (جمع‌وجور). روز امروز: حاشیهٔ تاکیدی، روز انتخابی: پر.
class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.showAll,
    required this.todayKey,
    required this.onDay,
    required this.onAll,
  });
  final List<String> days;
  final String? selected;
  final bool showAll;
  final String todayKey;
  final ValueChanged<String> onDay;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.fromLTRB(kTableMargin, 12, kTableMargin, 0),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppInk.line),
      ),
      child: LayoutBuilder(
        builder: (context, cons) {
          final n = days.length + 1;
          final w = ((cons.maxWidth - 8) / n).clamp(42.0, 84.0).toDouble();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final k in days)
                  _cell(
                    width: w,
                    selected: !showAll && selected == k,
                    today: k == todayKey,
                    top: jdayFromKey(k)?.weekdayShort ?? '',
                    bottom: jdayFromKey(k)?.dayText ?? k,
                    onTap: () => onDay(k),
                    p: p,
                  ),
                _cell(
                  width: w,
                  selected: showAll,
                  today: false,
                  top: 'همه',
                  bottom: null,
                  icon: Icons.view_week_rounded,
                  onTap: onAll,
                  p: p,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cell({
    required double width,
    required bool selected,
    required bool today,
    required String top,
    String? bottom,
    IconData? icon,
    required VoidCallback onTap,
    required AppPalette p,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: width - 4,
          height: 52,
          decoration: BoxDecoration(
            color: selected ? p.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: today && !selected ? p.accent : Colors.transparent, width: 1.6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(top, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: selected ? Colors.white70 : AppInk.muted)),
              const SizedBox(height: 2),
              if (bottom != null)
                Text(bottom, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.1, color: selected ? Colors.white : AppInk.ink))
              else
                Icon(icon, size: 17, color: selected ? Colors.white : AppInk.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// فیلتر شدت: همه / بالا / متوسط / پایین / تعطیل
class ImpactFilterBar extends StatelessWidget {
  const ImpactFilterBar({super.key, required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static const options = {'all': 'همه', 'high': 'بالا', 'medium': 'متوسط', 'low': 'پایین', 'holiday': 'تعطیل'};

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(kTableMargin, 8, kTableMargin, 8),
      child: Row(
        children: [
          for (final o in options.entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _pill(o.key, o.value, p),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String key, String label, AppPalette p) {
    final sel = value == key;
    final color = key == 'all' ? p.primary : ImpactBadge.style(key).$1;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 32,
        decoration: BoxDecoration(
          color: sel ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? color : AppInk.line),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (key != 'all') ...[
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: sel ? Colors.white : color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                ],
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppInk.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// سرستون ثابت جدول (Pinned)
class ColumnsHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 38;
  @override
  double get maxExtent => 38;

  Widget _c(String t, double w) => SizedBox(
        width: w,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ),
      );

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final p = context.pal;
    return ColoredBox(
      color: p.tint,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kTableMargin, 6, kTableMargin, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(color: p.secondary, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
          child: Row(
            children: [
              _c('ساعت', kColTime),
              _c('ارز', kColCur),
              _c('شدت', kColImpact),
              const Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: 4),
                  child: Text('رویداد', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
              ),
              _c('واقعی', kColVal),
              _c('پیش‌بینی', kColVal),
              _c('قبلی', kColVal),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

/// هدر گروه روز (در دل جدول)
class DayHeaderRow extends StatelessWidget {
  const DayHeaderRow({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kTableMargin),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(p.primary.withValues(alpha: 0.09), Colors.white),
        border: const Border(left: BorderSide(color: AppInk.line), right: BorderSide(color: AppInk.line), bottom: BorderSide(color: AppInk.line, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 14, decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.primary)),
        ],
      ),
    );
  }
}

/// پایان جدول (گوشه‌های گرد)
class TableFooter extends StatelessWidget {
  const TableFooter({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      margin: const EdgeInsets.fromLTRB(kTableMargin, 0, kTableMargin, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border.all(color: AppInk.line),
      ),
    );
  }
}

/// کارت پیام خالی داخل جدول
class TableEmpty extends StatelessWidget {
  const TableEmpty({super.key, this.text = 'رویدادی یافت نشد'});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kTableMargin),
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppInk.line), right: BorderSide(color: AppInk.line)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 40, color: AppInk.muted.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: AppInk.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

/// چیپ انتخابی ساده و هماهنگ با تم
class PillChoice extends StatelessWidget {
  const PillChoice({super.key, required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? p.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? p.primary : AppInk.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 15, color: selected ? Colors.white : AppInk.muted), const SizedBox(width: 5)],
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppInk.ink)),
          ],
        ),
      ),
    );
  }
}
