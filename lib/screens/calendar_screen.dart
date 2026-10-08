import '../widgets/banner_slot.dart';
import 'package:flutter/material.dart';

import '../api/endpoints.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import '../utils/tehran_time.dart';
import '../widgets/api_scope.dart';
import '../widgets/calendar_controls.dart';
import '../widgets/event_tile.dart';
import '../widgets/state_views.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  static const labels = kCalendarLabels;
  static final colors = {for (final e in kPalettes.entries) e.key: e.value.primary};

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  late final TabController _c;

  @override
  void initState() {
    super.initState();
    final start = Endpoints.calendarTypes.indexOf(activeCalendar.value);
    _c = TabController(length: Endpoints.calendarTypes.length, vsync: this, initialIndex: start < 0 ? 0 : start);
    _c.addListener(_onTab);
    activeCalendar.addListener(_onExternal);
  }

  void _onTab() {
    final t = Endpoints.calendarTypes[_c.index];
    if (activeCalendar.value != t) activeCalendar.value = t;
  }

  void _onExternal() {
    final i = Endpoints.calendarTypes.indexOf(activeCalendar.value);
    if (i >= 0 && i != _c.index) _c.animateTo(i);
  }

  @override
  void dispose() {
    activeCalendar.removeListener(_onExternal);
    _c.removeListener(_onTab);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(kTableMargin, 12, kTableMargin, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppInk.line),
            boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: TabBar(
            controller: _c,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(14)),
            labelColor: Colors.white,
            unselectedLabelColor: AppInk.muted,
            labelPadding: EdgeInsets.zero,
            splashBorderRadius: BorderRadius.circular(14),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            tabs: [
              for (final t in Endpoints.calendarTypes)
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(kCalendarIcons[t] ?? Icons.calendar_month, size: 15),
                      const SizedBox(width: 4),
                      Text(kCalendarShort[t] ?? t),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _c,
            children: [for (final t in Endpoints.calendarTypes) _CalendarList(type: t)],
          ),
        ),
      ],
    );
  }
}

class _CalendarList extends StatefulWidget {
  const _CalendarList({required this.type});
  final String type;
  @override
  State<_CalendarList> createState() => _CalendarListState();
}

class _CalendarListState extends State<_CalendarList> with AutomaticKeepAliveClientMixin {
  Future<CalendarResult>? _future;
  String _impactFilter = 'all';
  String? _selectedDayKey;
  bool _showAllDays = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= ApiScope.read(context).calendar(widget.type);
  }

  Future<void> _reload() async {
    final f = ApiScope.read(context).calendar(widget.type);
    setState(() {
      _future = f;
      _selectedDayKey = null;
      _showAllDays = false;
    });
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
    super.build(context);
    final p = context.pal;
    return FutureBuilder<CalendarResult>(
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
        var i = 0;
        for (final e in events) {
          final key = TehranTime.dayKey(e.date);
          if (key != lastDay) {
            lastDay = key;
            rows.add(DayHeaderRow(text: e.date == null ? 'بدون تاریخ' : (jdayFromKey(key)?.fullWithYear ?? key)));
            i = 0;
          }
          rows.add(EventTile(event: e, odd: i.isOdd));
          i++;
        }

        return Column(
  children: [
    Expanded(
      child: RefreshIndicator(
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
          ],
        ),
      ),
    ),
        BannerSlot(page: widget.type),
  ],
);
      },
    );
  }
}