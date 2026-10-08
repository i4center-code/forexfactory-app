import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import '../utils/tehran_time.dart';
import '../widgets/api_scope.dart';
import '../widgets/banner_slot.dart';
import '../widgets/calendar_controls.dart';
import '../widgets/event_tile.dart';
import '../widgets/state_views.dart';

/// تقویم بدون تب تکرارشوندهٔ بالای جدول — انتخاب تقویم فقط در هدر است.
/// [type] از هدر می‌آید (forex | metals | energy | crypto).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.type});
  final String type;

  static const labels = kCalendarLabels;
  static final colors = {for (final e in kPalettes.entries) e.key: e.value.primary};

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Future<CalendarResult>? _future;
  String _impactFilter = 'all';
  String? _selectedDayKey;
  bool _showAllDays = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _impactFilter = 'all';
      _selectedDayKey = null;
      _showAllDays = false;
      _load();
    }
  }

  void _load() {
    setState(() {
      _future = ApiScope.read(context).calendar(widget.type);
      _selectedDayKey = null;
      _showAllDays = false;
    });
  }

  Future<void> _reload() async {
    final f = ApiScope.read(context).calendar(widget.type);
    setState(() => _future = f);
    await f.catchError((_) => const CalendarResult([], null));
  }

  List<String> _dayKeys(List<CalendarEvent> events) {
    final keys = <String>{};
    for (final e in events) {
      final k = TehranTime.dayKey(e.date);
      if (k != 'unknown') keys.add(k);
    }
    return keys.toList()..sort();
  }

  String? _effectiveDay(List<String> days) {
    if (_showAllDays || days.isEmpty) return null;
    if (_selectedDayKey != null && days.contains(_selectedDayKey)) return _selectedDayKey;
    final today = TehranTime.date(DateTime.now());
    return days.contains(today) ? today : days.first;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      children: [
        // سرصفحهٔ نام تقویم (فقط متن، بدون تب قابل‌کلیک)
        Padding(
          padding: const EdgeInsets.fromLTRB(kTableMargin + 4, 12, kTableMargin + 4, 6),
          child: Row(
            children: [
              Icon(kCalendarIcons[widget.type] ?? Icons.calendar_month, size: 18, color: p.primary),
              const SizedBox(width: 6),
              Text(kCalendarLabels[widget.type] ?? 'تقویم', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.primary)),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<CalendarResult>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const LoadingView();
              if (snap.hasError) return ErrorView(error: snap.error!, onRetry: _reload);
              final result = snap.data!;
              final days = _dayKeys(result.events);
              final selectedDay = _effectiveDay(days);
              final events = result.events.where((e) {
                if (_impactFilter != 'all' && e.impact.toLowerCase() != _impactFilter) return false;
                if (selectedDay == null) return true;
                return TehranTime.dayKey(e.date) == selectedDay;
              }).toList()
                ..sort((a, b) => (a.date ?? DateTime(0)).compareTo(b.date ?? DateTime(0)));

              final rows = <Widget>[];
              String? lastDay;
              var rowIndex = 0;
              for (final ev in events) {
                final dayKey = TehranTime.dayKey(ev.date);
                if (dayKey != lastDay) {
                  lastDay = dayKey;
                  rows.add(DayHeaderRow(text: ev.date == null ? 'بدون تاریخ' : (jdayFromKey(dayKey)?.fullWithYear ?? dayKey)));
                  rowIndex = 0;
                }
                rows.add(EventTile(event: ev, odd: rowIndex.isOdd));
                rowIndex++;
              }

              return RefreshIndicator(
                color: p.primary,
                onRefresh: _reload,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: DayStrip(
                        days: days,
                        selected: selectedDay,
                        showAll: _showAllDays,
                        todayKey: TehranTime.date(DateTime.now()),
                        onDay: (k) => setState(() {
                          _showAllDays = false;
                          _selectedDayKey = k;
                        }),
                        onAll: () => setState(() {
                          _showAllDays = true;
                          _selectedDayKey = null;
                        }),
                      ),
                    ),
                    SliverToBoxAdapter(child: ImpactFilterBar(value: _impactFilter, onChanged: (v) => setState(() => _impactFilter = v))),
                    SliverPersistentHeader(pinned: true, delegate: ColumnsHeaderDelegate()),
                    if (rows.isEmpty) const SliverToBoxAdapter(child: TableEmpty()) else SliverList(delegate: SliverChildListDelegate(rows)),
                    const SliverToBoxAdapter(child: TableFooter()),
                    const SliverToBoxAdapter(child: SizedBox(height: 4)),
                  ],
                ),
              );
            },
          ),
        ),
        // بنر پایین جدول — از banner.php، دست‌نخورده
        BannerSlot(page: widget.type),
      ],
    );
  }
}
