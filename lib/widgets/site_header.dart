import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import 'rate_bar.dart';

/// هدر سایت (الهام از forexfactoryiran.ir) + نوار نرخ بهره زیر آن.
///
/// - منو فقط: فارکس، کریپتو، فلزات، انرژی، بروکرها، اخبار، ورود
/// - بدون همبرگر / سوییچ FA/EN / جستجوی غیرواکنش
/// - دکمهٔ برگشت داخل هدر (وقتی صفحه‌ای روی بقیه باز شده باشد)
/// - رنگ کل هدر و تب‌ها با تقویم فعال عوض می‌شود؛
///   تب غیرفعال از همان خانوادهٔ رنگ صفحه است، نه آبی ثابت.
class SiteHeader extends StatefulWidget {
  const SiteHeader({
    super.key,
    required this.section,
    required this.onSection,
    this.showBack = false,
    this.onBack,
    this.backLabel,
  });

  /// forex | crypto | metals | energy | brokers | news | account | login | ticket | charge ...
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

  static const items = <_NavItem>[
    _NavItem('forex', 'فارکس', Icons.candlestick_chart_outlined),
    _NavItem('crypto', 'کریپتو', Icons.currency_bitcoin_rounded),
    _NavItem('metals', 'فلزات', Icons.diamond_outlined),
    _NavItem('energy', 'انرژی', Icons.bolt_rounded),
    _NavItem('brokers', 'بروکرها', Icons.business_center_outlined),
    _NavItem('news', 'اخبار', Icons.newspaper_outlined),
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

  @override
  Widget build(BuildContext context) {
    final cal = activeCalendar.value;
    final p = paletteOf(cal);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // هدر — رنگ از تم تقویم فعال (حتی تب‌های غیرفعال)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.secondary, p.primary]),
              border: Border(bottom: BorderSide(color: p.accent, width: 4)),
            ),
            child: wide ? _desktop(p) : _phone(p),
          ),
          // نوار نرخ بهره — همان جای خالی زیر هدر
          const RateBar(),
        ],
      ),
    );
  }

  Widget _desktop(AppPalette p) {
    return SizedBox(
      height: 66,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 236),
              child: Row(
                children: [
                  Expanded(child: _tabs(p)),
                  _tools(p),
                ],
              ),
            ),
          ),
          PositionedDirectional(top: 0, start: 0, child: _slab(p)),
        ],
      ),
    );
  }

  Widget _phone(AppPalette p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (widget.showBack) _backBtn(p),
              Expanded(child: _brandRow(p)),
              const SizedBox(width: 6),
              _clockChip(p),
              _loginChip(p),
            ],
          ),
        ),
        SizedBox(height: 42, child: _tabs(p)),
      ],
    );
  }

  Widget _backBtn(AppPalette p) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
  }

  Widget _slab(AppPalette p) {
    return SizedBox(
      width: 236,
      height: 66,
      child: Stack(
        children: [
          CustomPaint(size: const Size(236, 66), painter: _SlabPainter(p.secondary, p.primary, p.accent)),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 32, 4),
            child: Row(
              children: [
                if (widget.showBack) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(child: _brandRow(p)),
              ],
            ),
          ),
        ],
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
        Image.asset(logo, height: 34, errorBuilder: (_, __, ___) => Image.asset('assets/branding/forex-logo.png', height: 34)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('فارکس فکتوری ایران', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.2)),
              Text(widget.backLabel ?? sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF7F7F7), fontSize: 10, height: 1.2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabs(AppPalette p) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.only(start: 6),
      children: [
        for (final it in items)
          _Tab(
            label: it.label,
            icon: it.icon,
            selected: widget.section == it.key,
            palette: p,
            onTap: () {
              if (it.isCalendar) {
                activeCalendar.value = it.key;
                appThemeKey.value = it.key;
              }
              widget.onSection(it.key);
            },
          ),
      ],
    );
  }

  Widget _tools(AppPalette p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _clockChip(p),
        _loginChip(p),
      ],
    );
  }

  Widget _clockChip(AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 13, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(_clock, textDirection: TextDirection.ltr, style: const TextStyle(color: Color(0xFFE3EBFB), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _loginChip(AppPalette p) {
    final onAccount = widget.section == 'account' || widget.section == 'login';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => widget.onSection('account'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: onAccount ? p.accent : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: onAccount ? p.accent : Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(onAccount ? Icons.person_rounded : Icons.person_outline_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 4),
              Text(onAccount ? 'حساب' : 'ورود', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
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
    final inactiveBg = Color.alphaBlend(palette.primary.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.35));
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: ClipPath(
        clipper: _SkewClip(),
        child: Material(
          color: selected ? palette.accent : inactiveBg,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white.withValues(alpha: 0.88), fontSize: 13, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkewClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const s = 14.0;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - s, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(s, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SlabPainter extends CustomPainter {
  _SlabPainter(this.top, this.bottom, this.accent);
  final Color top;
  final Color bottom;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(28, size.height)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawLine(const Offset(17, 40), Offset(size.width, size.height - 2), stroke);
  }

  @override
  bool shouldRepaint(covariant _SlabPainter oldDelegate) => oldDelegate.top != top || oldDelegate.bottom != bottom || oldDelegate.accent != accent;
}
