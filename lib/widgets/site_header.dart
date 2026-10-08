import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import 'rate_bar.dart';

/// فیلتر متنی رویدادهای تقویم فعال (توسط CalendarScreen خوانده می‌شود).
final ValueNotifier<String> calendarSearchQuery = ValueNotifier<String>('');

/// باز کردن لینک بیرونی در تب جدید — نسخهٔ وب (package:web)
Future<void> openExternalUrl(String url) async {
  try {
    await _openTab(url);
  } catch (_) {}
}

/// جای‌نما (غیر وب): کاری نمی‌کند.
Future<void> _openTabStub() async {}

/// هدر سایت (الهام از forexfactoryiran.ir) + نوار نرخ بهره زیر آن.
///
/// - صاف و مستطیلی، بدون شیب/کلیپ — ارتفاع جمع‌وجور ~۴۸px
/// - منو فقط: فارکس، کریپتو، فلزات، انرژی، بروکرها، اخبار
///   (آیکون خطی ۱۶px سفید، دکمه ۳۲px، فاصله ۸px، در موبایل اسکرول افقی)
/// - دکمه ورود/حساب: قرص سفید با متن سرمه‌ای و آیکون آدمک
/// - ساعت تهران (فقط ساعت:دقیقه) در قرص شیشه‌ای کنار ورود
/// - دکمه جستجو: فیلد باز می‌شود و عنوان رویدادهای همان تقویم فیلتر می‌شود
/// - رنگ کل هدر با تقویم فعال عوض می‌شود؛ تب غیرفعال هم‌خانوادهٔ همان تم
class SiteHeader extends StatefulWidget {
  const SiteHeader({
    super.key,
    required this.section,
    required this.onSection,
    this.showBack = false,
    this.onBack,
    this.backLabel,
  });

  /// forex | crypto | metals | energy | brokers | news | account | login | ticket ...
  final String section;
  final ValueChanged<String> onSection;
  final bool showBack;
  final VoidCallback? onBack;
  final String? backLabel;

  @override
  State<SiteHeader> createState() => _SiteHeaderState();
}

class _SiteHeaderState extends State<SiteHeader> {
  Timer? _timer;
  String _clock = '--:--';
  bool _searchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();

  static const items = <_NavItem>[
    _NavItem('forex', 'فارکس', Icons.bar_chart_rounded),
    _NavItem('crypto', 'کریپتو', Icons.monetization_on_outlined),
    _NavItem('metals', 'فلزات', Icons.horizontal_split_rounded),
    _NavItem('energy', 'انرژی', Icons.local_fire_department_outlined),
    _NavItem('brokers', 'بروکرها', Icons.account_balance_outlined),
    _NavItem('news', 'اخبار', Icons.article_outlined),
  ];

  @override
  void initState() {
    super.initState();
    activeCalendar.addListener(_onCal);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
  }

  @override
  void dispose() {
    activeCalendar.removeListener(_onCal);
    _timer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onCal() {
    if (mounted) setState(() {});
  }

  void _tick() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3, minutes: 30));
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    if (mounted) setState(() => _clock = toFa('$hh:$mm', decimal: false));
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _searchCtrl.clear();
      calendarSearchQuery.value = '';
    }
  }

  void _go(String key) {
    if (const {'forex', 'crypto', 'metals', 'energy'}.contains(key)) {
      activeCalendar.value = key;
      appThemeKey.value = key;
    }
    widget.onSection(key);
  }

  @override
  Widget build(BuildContext context) {
    final cal = activeCalendar.value;
    final p = paletteOf(cal);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // هدر صاف — رنگ از تم تقویم فعال
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: p.primary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 48, child: _bar(p)),
                if (_searchOpen) _searchField(p),
              ],
            ),
          ),
          // نوار نرخ بهره — همان جای خالی زیر هدر
          const RateBar(),
        ],
      ),
    );
  }

  Widget _bar(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (widget.showBack) _backBtn(p),
          Flexible(flex: 3, child: _brandRow(p)),
          const SizedBox(width: 8),
          // منو — در موبایل جمع می‌شود (اسکرول افقی، بیرون نمی‌زند)
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final it in items)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _Tab(
                        label: it.label,
                        icon: it.icon,
                        selected: widget.section == it.key,
                        palette: p,
                        onTap: () => _go(it.key),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _iconBtn(p, Icons.search_rounded, _toggleSearch, active: _searchOpen),
          _clockChip(p),
          const SizedBox(width: 6),
          _loginChip(p),
        ],
      ),
    );
  }

  Widget _backBtn(AppPalette p) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
  }

  Widget _brandRow(AppPalette p) {
    final type = activeCalendar.value;
    final sub = switch (type) {
      'metals' => 'تقویم فلزات',
      'energy' => 'تقویم انرژی',
      'crypto' => 'تقویم کریپتو',
      _ => 'تقویم فارکس',
    };
    final logo = 'assets/branding/$type-logo.png';
    return Row(
      children: [
        Image.asset(logo, height: 26, errorBuilder: (_, __, ___) => Image.asset('assets/branding/forex-logo.png', height: 26)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('فارکس فکتوری ایران', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.2)),
              Text(widget.backLabel ?? sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, height: 1.2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchField(AppPalette p) {
    return Container(
      color: p.primary,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: (v) => calendarSearchQuery.value = v.trim(),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'جستجو در رویدادهای همین تقویم…',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5),
          isDense: true,
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.white70),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
            onPressed: _toggleSearch,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.12),
          contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Colors.white, width: 1.2)),
        ),
      ),
    );
  }

  Widget _iconBtn(AppPalette p, IconData icon, VoidCallback onTap, {bool active = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        margin: const EdgeInsets.only(left: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _clockChip(AppPalette p) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      margin: const EdgeInsets.only(left: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 13, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 4),
          Text(_clock, textDirection: TextDirection.ltr, style: const TextStyle(color: Color(0xFFEAF0FB), fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _loginChip(AppPalette p) {
    final onAccount = widget.section == 'account' || widget.section == 'login';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.onSection('account'),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(onAccount ? Icons.person_rounded : Icons.person_outline_rounded, size: 15, color: const Color(0xFF1B346A)),
            const SizedBox(width: 4),
            Text(onAccount ? 'حساب' : 'ورود', style: const TextStyle(color: Color(0xFF1B346A), fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
  bool get isCalendar => const {'forex', 'crypto', 'metals', 'energy'}.contains(key);
}

/// دکمهٔ مستطیلی هدر — بدون شیب، ارتفاع ۳۲، فاصله ۸ از همسایه.
class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.icon, required this.selected, required this.palette, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // تب غیرفعال: همان خانوادهٔ رنگ صفحه (نه آبی ثابت فارکس)
    final inactiveBg = Colors.white.withValues(alpha: 0.10);
    return Material(
      color: selected ? palette.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: selected ? null : Border.all(color: Colors.white.withValues(alpha: 0.16)),
            color: selected ? null : inactiveBg,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white.withValues(alpha: 0.9), fontSize: 12.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
