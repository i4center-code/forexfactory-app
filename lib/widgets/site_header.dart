import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/account_screen.dart';
import '../theme/app_theme.dart';
import '../utils/fa_format.dart';

/// هدر عین سایت: اسلب کج، تب‌های مورب، ساعت تهران، جستجو، ورود.
class SiteHeader extends StatefulWidget {
  const SiteHeader({
    super.key,
    required this.section,
    required this.onSection,
    this.onMenu,
  });

  /// forex | crypto | metals | energy | brokers | news
  final String section;
  final ValueChanged<String> onSection;
  final VoidCallback? onMenu;

  @override
  State<SiteHeader> createState() => _SiteHeaderState();
}

class _SiteHeaderState extends State<SiteHeader> {
  Timer? _timer;
  String _clock = '--:--';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      child: Material(
        color: p.secondary,
        child: wide ? _desktop(p) : _phone(p),
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
              padding: const EdgeInsetsDirectional.only(start: 222),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.secondary, p.primary]),
                  border: Border(bottom: BorderSide(color: p.accent, width: 4)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _tabs(p)),
                    _tools(p),
                  ],
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.secondary, p.primary]),
            border: Border(bottom: BorderSide(color: p.accent, width: 4)),
          ),
          child: _brandRow(p),
        ),
        Container(color: p.primary, height: 40, child: _tabs(p)),
        Container(
          height: 36,
          color: Color.lerp(p.primary, Colors.black, 0.12),
          child: _tools(p),
        ),
      ],
    );
  }

  Widget _slab(AppPalette p) {
    return SizedBox(
      width: 236,
      height: 66,
      child: Stack(
        children: [
          CustomPaint(size: const Size(236, 66), painter: _SlabPainter(p.secondary, p.primary, p.accent)),
          Padding(padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 32, 4), child: _brandRow(p)),
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
    final logo = 'assets/branding/${type == 'forex' ? 'forex' : type}-logo.png';
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
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF7F7F7), fontSize: 10, height: 1.2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabs(AppPalette p) {
    const items = [
      ('forex', 'فارکس', Icons.candlestick_chart_outlined),
      ('crypto', 'کریپتو', Icons.currency_bitcoin),
      ('metals', 'فلزات', Icons.hexagon_outlined),
      ('energy', 'انرژی', Icons.local_fire_department_outlined),
      ('brokers', 'بروکرها', Icons.business_center_outlined),
      ('news', 'اخبار', Icons.newspaper_outlined),
    ];
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final it in items)
          _Tab(
            label: it.$2,
            icon: it.$3,
            selected: widget.section == it.$1,
            accent: p.accent,
            onTap: () {
              if (it.$1 == 'forex' || it.$1 == 'crypto' || it.$1 == 'metals' || it.$1 == 'energy') {
                activeCalendar.value = it.$1;
                appThemeKey.value = it.$1;
              }
              widget.onSection(it.$1);
            },
          ),
      ],
    );
  }

  Widget _tools(AppPalette p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tool(const Text('FA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
        _tool(Text(_clock, style: const TextStyle(color: Color(0xFFE3EBFB), fontSize: 13))),
        _tool(const Icon(Icons.search, color: Color(0xFFE3EBFB), size: 16), onTap: () => widget.onSection('forex')),
        if (widget.onMenu != null) _tool(const Icon(Icons.menu, color: Color(0xFFE3EBFB), size: 16), onTap: widget.onMenu),
        _tool(const Icon(Icons.person_outline, color: Color(0xFFE3EBFB), size: 16), label: 'ورود', onTap: () => _openAccount(context)),
      ],
    );
  }

  Widget _tool(Widget child, {String? label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: const BoxDecoration(border: BorderDirectional(start: BorderSide(color: Color(0x1FFFFFFF)))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            if (label != null) ...[const SizedBox(width: 4), Text(label, style: const TextStyle(color: Color(0xFFE3EBFB), fontSize: 12))],
          ],
        ),
      ),
    );
  }

  void _openAccount(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AccountScreen()));
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.icon, required this.selected, required this.accent, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: ClipPath(
        clipper: _SkewClip(),
        child: Material(
          color: selected ? accent : const Color(0xFF3D5B99),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
