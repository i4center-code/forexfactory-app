import 'package:flutter/material.dart';

import '../api/endpoints.dart';
import '../app_version.dart';
import '../sales/sales_entry.dart';
import '../screens/charge_screen.dart';
import '../screens/info_screen.dart';
import '../screens/paid_calendar_screen.dart';
import '../theme/app_theme.dart';
import '../utils/fa_format.dart';

/// منوی کشویی؛ فقط صفحات داخلی (بدون هیچ لینک بیرونی).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.onCalendar, required this.onTab, required this.onOpen});
  final ValueChanged<String> onCalendar;
  final ValueChanged<int> onTab;
  final ValueChanged<Widget> onOpen;

  void _do(BuildContext c, VoidCallback f) {
    Navigator.of(c).pop();
    f();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Drawer(
      width: 306,
      backgroundColor: p.tint,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          _header(p),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              children: [
                const _Label('تقویم‌ها'),
                for (final t in Endpoints.calendarTypes)
                  _Item(
                    icon: kCalendarIcons[t] ?? Icons.calendar_month,
                    title: kCalendarLabels[t] ?? t,
                    dot: paletteOf(t).primary,
                    onTap: () => _do(context, () => onCalendar(t)),
                  ),
                const _Label('خبر و حساب'),
                _Item(icon: Icons.newspaper_rounded, title: 'اخبار', onTap: () => _do(context, () => onTab(1))),
                _Item(icon: Icons.person_rounded, title: 'حساب کاربری', onTap: () => _do(context, () => onTab(2))),
                _Item(icon: Icons.confirmation_number_rounded, title: 'تیکت‌ها', onTap: () => _do(context, () => onTab(2))),
                _Item(icon: Icons.account_balance_wallet_rounded, title: 'شارژ کیف پول', onTap: () => _do(context, () => onOpen(const ChargeScreen()))),
                const _Label('ابزارها'),
                _Item(icon: Icons.api_rounded, title: 'وضعیت API', onTap: () => _do(context, () => onOpen(const SalesHomeRoute()))),
                _Item(icon: Icons.workspace_premium_rounded, title: 'تقویم پولی', onTap: () => _do(context, () => onOpen(const PaidCalendarScreen()))),
                _Item(icon: Icons.signal_cellular_alt_rounded, title: 'راهنمای شدت خبر', onTap: () => _do(context, () => onOpen(InfoScreen.impactGuide()))),
                const _Label('اپلیکیشن'),
                _Item(icon: Icons.palette_rounded, title: 'تنظیمات ظاهر', onTap: () => _do(context, () => onOpen(InfoScreen.appearance()))),
                _Item(icon: Icons.quiz_rounded, title: 'پرسش‌های متداول', onTap: () => _do(context, () => onOpen(InfoScreen.faq()))),
                _Item(icon: Icons.support_agent_rounded, title: 'پشتیبانی', onTap: () => _do(context, () => onOpen(InfoScreen.support()))),
                _Item(icon: Icons.info_rounded, title: 'دربارهٔ ما', onTap: () => _do(context, () => onOpen(InfoScreen.about()))),
                _Item(icon: Icons.gavel_rounded, title: 'قوانین و حریم خصوصی', onTap: () => _do(context, () => onOpen(InfoScreen.terms()))),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text('نسخه ${toFa(kAppVersion, decimal: false)}', style: const TextStyle(fontSize: 11, color: AppInk.muted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [p.primary, p.secondary]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(18)),
                child: Image.asset('assets/branding/forex-logo.png'),
              ),
              const SizedBox(height: 14),
              const Text('فارکس فکتوری ایران', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('تقویم اقتصادی فارسی', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppInk.muted)),
      );
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, required this.onTap, this.dot});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 19, color: p.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400))),
              if (dot != null) Container(width: 9, height: 9, margin: const EdgeInsets.only(left: 6), decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const Icon(Icons.chevron_left_rounded, size: 20, color: AppInk.muted),
            ],
          ),
        ),
      ),
    );
  }
}
