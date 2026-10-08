import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/site_header.dart';
import 'account_screen.dart';
import 'brokers_screen.dart';
import 'calendar_screen.dart';
import 'news_screen.dart';

/// صفحهٔ اصلی: هدر سایت + نوار نرخ بهره (داخل SiteHeader) + بدنهٔ بخش فعال.
/// بنر بالای جدول حذف شده؛ بنر واقعی (BannerSlot) پایین جدول تقویم می‌ماند.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _section = 'forex';

  @override
  void initState() {
    super.initState();
    appThemeKey.value = 'forex';
    activeCalendar.value = 'forex';
  }

  void _setSection(String s) {
    if (s == 'account') {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AccountPage()));
      return;
    }
    setState(() => _section = s);
    if (s == 'forex' || s == 'crypto' || s == 'metals' || s == 'energy') {
      activeCalendar.value = s;
      appThemeKey.value = s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_section) {
      'news' => const NewsScreen(),
      'brokers' => const BrokersScreen(),
      _ => CalendarScreen(key: ValueKey('cal-$_section'), type: _section),
    };
    return Scaffold(
      body: Column(
        children: [
          SiteHeader(section: _section, onSection: _setSection),
          Expanded(child: body),
        ],
      ),
    );
  }
}
