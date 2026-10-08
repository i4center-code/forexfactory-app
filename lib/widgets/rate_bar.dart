import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../utils/fa_format.dart';

/// نوار نرخ بهره زیر هدر — منبع: https://forexfactoryiran.ir/rates-api.php
/// پاسخ JSON با فیلد `rates` (نماد ارز → درصد). در صورت خطا/خالی بودن،
/// صفحه نمی‌شکند و فقط یک خط باریک نمایش داده می‌شود.
/// ظاهر: عنوان ثابت «نرخ بهره» در ابتدای نوار + رنگ پس‌زمینه هماهنگ با تم صفحه.
class RateBar extends StatefulWidget {
  const RateBar({super.key});

  @override
  State<RateBar> createState() => _RateBarState();
}

class _RateBarState extends State<RateBar> {
  static const _url = 'https://forexfactoryiran.ir/rates-api.php';
  static const _order = ['USD', 'EUR', 'GBP', 'CHF', 'CAD', 'AUD', 'NZD', 'JPY'];
  static const _names = {
    'USD': 'دلار', 'EUR': 'یورو', 'GBP': 'پوند', 'CHF': 'فرانک',
    'CAD': 'دلار کانادا', 'AUD': 'دلار استرالیا', 'NZD': 'دلار نیوزیلند', 'JPY': 'ین',
  };

  /// رنگ نوار نرخ بهره به تفکیک تقویم فعال (هم‌خانوادهٔ تم صفحه)
  static const _barColors = <String, Color>{
    'forex': Color(0xFF223D7A),
    'crypto': Color(0xFF463459),
    'metals': Color(0xFF5A2C26),
    'energy': Color(0xFF1A6231),
  };

  List<_Rate>? _rates;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse(_url)).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return;
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final raw = data is Map ? data['rates'] : null;
      if (raw is! Map) return;
      final list = <_Rate>[];
      for (final sym in _order) {
        final v = double.tryParse((raw[sym] ?? '').toString());
        if (v != null) list.add(_Rate(sym, v));
      }
      // نمادهای ناشناخته (اگر سرور اضافه کرد) در انتها
      for (final e in raw.entries) {
        if (!_order.contains(e.key)) {
          final v = double.tryParse((e.value ?? '').toString());
          if (v != null) list.add(_Rate(e.key.toString(), v));
        }
      }
      if (mounted) setState(() => _rates = list);
    } catch (_) {
      // سکوت: صفحه نباید بشکند
    }
  }

  String _pct(double v) {
    var s = v.abs().toStringAsFixed(2);
    if (s.endsWith('.00')) {
      s = s.substring(0, s.length - 3);
    } else if (s.endsWith('0') && s.contains('.')) {
      s = s.substring(0, s.length - 1);
    }
    final sign = v < 0 ? '−' : '';
    return toFa('$sign$s٪', decimal: false);
  }

  @override
  Widget build(BuildContext context) {
    final cal = activeCalendar.value;
    final p = paletteOf(cal);
    final bg = _barColors[cal] ?? p.primary;
    final rates = _rates;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: bg,
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.accent.withValues(alpha: 0.55), width: 2)),
          ),
          child: Row(
            children: [
              // عنوان ثابت نوار — قبل از عددها
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.percent_rounded, size: 13, color: p.accent),
                    const SizedBox(width: 4),
                    Text('نرخ بهره', style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 11.5, fontWeight: FontWeight.w800, fontFamily: kFont)),
                  ],
                ),
              ),
              Container(width: 1, height: 18, color: Colors.white.withValues(alpha: 0.22)),
              Expanded(
                child: rates == null || rates.isEmpty
                    ? Center(
                        child: Text('نرخ بهرهٔ بانک‌های مرکزی', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5)),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: rates.length,
                        separatorBuilder: (_, __) => VerticalDivider(width: 1, color: Colors.white.withValues(alpha: 0.14)),
                        itemBuilder: (context, i) {
                          final r = rates[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  r.value >= 0 ? Icons.trending_up : Icons.trending_down,
                                  size: 13,
                                  color: r.value >= 0 ? p.accent : const Color(0xFFFF8A80),
                                ),
                                const SizedBox(width: 5),
                                Text(_names[r.sym] ?? r.sym, style: const TextStyle(color: Color(0xFFE4EAF6), fontSize: 11)),
                                const SizedBox(width: 5),
                                Text(_pct(r.value),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rate {
  const _Rate(this.sym, this.value);
  final String sym;
  final double value;
}
