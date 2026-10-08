import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sales/sales_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/site_header.dart';
import 'account_screen.dart';
import 'brokers_screen.dart';
import 'calendar_screen.dart';
import 'news_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffold = GlobalKey<ScaffoldState>();
  String _section = 'forex';

  @override
  void initState() {
    super.initState();
    appThemeKey.value = 'forex';
    activeCalendar.value = 'forex';
  }

  void _setSection(String s) {
    setState(() => _section = s);
    if (s == 'forex' || s == 'crypto' || s == 'metals' || s == 'energy') {
      activeCalendar.value = s;
      appThemeKey.value = s;
    }
  }

  void _link(String title, String url) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
            },
            child: const Text('کپی لینک'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_section) {
      'news' => const NewsScreen(),
      'brokers' => const BrokersScreen(),
      _ => const CalendarScreen(),
    };
    final p = paletteOf(activeCalendar.value);
    return Scaffold(
      key: _scaffold,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: p.primary,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                child: Row(
                  children: [
                    Image.asset('assets/branding/forex-logo.png', height: 40),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('فارکس فکتوری ایران', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('نمایش تقویم و حساب', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const _Label('سایت'),
              _item(Icons.language, 'باز کردن سایت', () => _link('سایت', 'https://forexfactoryiran.ir')),
              _item(Icons.dashboard_outlined, 'داشبورد سایت', () => _link('داشبورد', 'https://forexfactoryiran.ir/dashboard')),
              const _Label('راهنما'),
              _item(Icons.menu_book_outlined, 'مستندات API', () => _link('مستندات', 'https://forexfactoryiran.ir/api-docs')),
              _item(Icons.privacy_tip_outlined, 'شرایط استفاده', () => _link('شرایط', 'https://forexfactoryiran.ir/terms')),
              _item(Icons.verified_outlined, 'نماد اعتماد', () => _link('نماد', 'https://forexfactoryiran.ir/enamad.php')),
              const _Label('داخل اپ'),
              ListTile(
                leading: Icon(Icons.manage_accounts_outlined, color: p.primary),
                title: const Text('حساب', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AccountScreen()));
                },
              ),
              ListTile(
                leading: Icon(Icons.api_outlined, color: p.primary),
                title: const Text('وضعیت API', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SalesHomeRoute()));
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SiteHeader(section: _section, onSection: _setSection, onMenu: () => _scaffold.currentState?.openDrawer()),
          const BannerPlaceholder(),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: paletteOf(activeCalendar.value).primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5D6A90))),
    );
  }
}
