import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import '../utils/tehran_time.dart';
import 'impact_badge.dart';

// عرض ستون‌های جدول (مشترک با سرستون)
const double kColTime = 36;
const double kColCur = 34;
const double kColImpact = 28;
const double kColVal = 38;
const double kTableMargin = 8;

/// یک ردیف جدول تقویم: ساعت، ارز، شدت، رویداد، واقعی، پیش‌بینی، قبلی
class EventTile extends StatefulWidget {
  const EventTile({super.key, required this.event, this.odd = false});
  final CalendarEvent event;
  final bool odd;

  @override
  State<EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<EventTile> {
  bool _open = false;

  Widget _val(String v, Color color, {bool strong = false}) {
    final empty = v.isEmpty;
    return SizedBox(
      width: kColVal,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          empty ? '—' : toFa(v),
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
            color: empty ? AppInk.muted : color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kTableMargin),
      decoration: BoxDecoration(
        color: widget.odd ? Color.alphaBlend(p.primary.withValues(alpha: 0.035), Colors.white) : Colors.white,
        border: const Border(
          left: BorderSide(color: AppInk.line),
          right: BorderSide(color: AppInk.line),
          bottom: BorderSide(color: AppInk.line, width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: kColTime,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(toFa(TehranTime.time(e.date)), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                SizedBox(
                  width: kColCur,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(e.country, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppInk.muted)),
                  ),
                ),
                SizedBox(width: kColImpact, child: Center(child: ImpactBadge(impact: e.impact, size: 22))),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.displayTitle, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.35)),
                        if (e.title.isNotEmpty)
                          Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 9.5, color: AppInk.muted)),
                        if (e.hasAnalysis)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setState(() => _open = !_open),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_open ? 'بستن' : 'تحلیل', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.primary)),
                                    Icon(_open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 14, color: p.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _val(e.actual, p.primary, strong: true),
                _val(e.forecast, AppInk.ink),
                _val(e.previous, AppInk.muted),
              ],
            ),
          ),
          if (e.hasAnalysis)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _open
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.tint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border(right: BorderSide(color: p.accent, width: 3)),
                      ),
                      child: Text(toFa(e.displayAnalysis), style: const TextStyle(fontSize: 11.5, height: 1.8)),
                    )
                  : const SizedBox(width: double.infinity),
            ),
        ],
      ),
    );
  }
}
