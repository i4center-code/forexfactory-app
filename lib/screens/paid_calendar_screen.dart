import 'package:flutter/material.dart';

import '../api/endpoints.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import '../utils/tehran_time.dart';
import '../widgets/api_scope.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/calendar_controls.dart';
import '../widgets/event_tile.dart';
import '../widgets/state_views.dart';

/// Fetches `/data/calendar/{type}` with `X-API-Key`. Falls back to public
/// `/calendar/{type}` when the paid route is not deployed (404).
class PaidCalendarScreen extends StatefulWidget {
  const PaidCalendarScreen({super.key});
  @override
  State<PaidCalendarScreen> createState() => _PaidCalendarScreenState();
}

class _PaidCalendarScreenState extends State<PaidCalendarScreen> {
  String _type = 'forex';
  Future<CalendarResult>? _future;
  String? _selectedRaw;
  String? _selectedDayKey;
  bool _showAllDays = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = ApiScope.of(context);
    _selectedRaw ??= api.store.selectedApiKey?.raw;
    _future ??= _load();
  }

  Future<CalendarResult> _load() {
    final api = ApiScope.read(context);
    return api.paidCalendar(_type, apiKey: _selectedRaw);
  }

  Future<void> _reload() async {
    final f = _load();
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
    final api = ApiScope.of(context);
    final stored = api.store.storedApiKeys;

    return AnimatedTheme(
      data: buildAppTheme(paletteOf(_type)),
      duration: const Duration(milliseconds: 300),
      child: Builder(builder: (context) {
        final p = context.pal;
        return Scaffold(
          appBar: const BrandAppBar(subtitle: 'تقویم پولی (کلید API)'),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.vpn_key_rounded, size: 16, color: p.primary),
                        const SizedBox(width: 6),
                        const Text('کلید API ذخیره‌شده', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (stored.isEmpty)
                      const Text('کلیدی روی دستگاه ذخیره نشده. از بخش «کلیدهای API» یک کلید بسازید.', style: TextStyle(fontSize: 11.5, color: AppInk.muted))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final k in stored)
                            PillChoice(
                              label: k.name.isNotEmpty ? k.name : k.display,
                              selected: _selectedRaw == k.raw || (_selectedRaw == null && k.raw == stored.last.raw),
                              onTap: () async {
                                setState(() => _selectedRaw = k.raw);
                                await api.selectLocalApiKey(k.id);
                                await _reload();
                              },
                            ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final t in Endpoints.calendarTypes)
                          PillChoice(
                            label: kCalendarShort[t] ?? t,
                            icon: kCalendarIcons[t],
                            selected: _type == t,
                            onTap: () {
                              setState(() => _type = t);
                              _reload();
                            },
                          ),
                      ],
                    ),
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
                    final events = result.events
                        .where((e) => selectedDay == null || TehranTime.dayKey(e.date) == selectedDay)
                        .toList()
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

                    return RefreshIndicator(
                      color: p.primary,
                      onRefresh: _reload,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (result.fallbackNote != null)
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(kTableMargin, 12, kTableMargin, 0),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: p.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(result.fallbackNote!, style: const TextStyle(fontSize: 12, height: 1.6))),
                                  ],
                                ),
                              ),
                            ),
                          if (result.fromPaidEndpoint)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text('منبع: تقویم پولی با کلید API', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppInk.muted)),
                              ),
                            ),
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
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          SliverPersistentHeader(pinned: true, delegate: ColumnsHeaderDelegate()),
                          if (rows.isEmpty) const SliverToBoxAdapter(child: TableEmpty()) else SliverList(delegate: SliverChildListDelegate(rows)),
                          const SliverToBoxAdapter(child: TableFooter()),
                          if (result.generatedAt != null)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text(
                                  'به‌روزرسانی: ${faDateTime(result.generatedAt)} (تهران)',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: AppInk.muted),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
