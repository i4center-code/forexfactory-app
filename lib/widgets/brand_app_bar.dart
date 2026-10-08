import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// هدر برند: «فارکس فکتوری ایران» + نام صفحه/تقویم. رنگ از تم فعال.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key, required this.subtitle, this.actions});
  final String subtitle;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppBar(
      toolbarHeight: 68,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [p.primary, p.secondary]),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
          boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 5))],
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('فارکس فکتوری ایران', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.25)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              subtitle,
              key: ValueKey(subtitle),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 11.5, height: 1.3),
            ),
          ),
        ],
      ),
      actions: [
        ...?actions,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Image.asset('assets/branding/forex-logo.png', height: 32),
        ),
      ],
    );
  }
}

/// جای خالی بنر (ارتفاع ثابت ۹۰). داده بنر وصل نشده.
class BannerPlaceholder extends StatelessWidget {
  const BannerPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      height: 90,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.primary.withValues(alpha: 0.10)),
      ),
    );
  }
}
