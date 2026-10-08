import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../app_version.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import '../sales/format.dart';
import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import '../widgets/api_scope.dart';
import '../widgets/state_views.dart';
import 'charge_screen.dart';
import 'login_screen.dart';
import 'tickets_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiScope.of(context);
    return Column(
      children: [
        Expanded(child: api.isLoggedIn ? const _ProfileView() : const LoginScreen()),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Text('نسخه ${toFa(kAppVersion, decimal: false)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppInk.muted)),
        ),
      ],
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();
  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  Future<_Dash>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_Dash> _load() async {
    final api = ApiScope.read(context);
    final me = await api.me();
    final res = await http.get(Uri.parse('https://forexfactoryiran.ir/api/public/app-panel.php?email=${Uri.encodeComponent(me.email)}'));
    final data = res.statusCode == 200 ? jsonDecode(res.body) : {};
    List<Map<String, dynamic>> list(dynamic v) => v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    return _Dash(me, list(data['keys']), list(data['ads']), list(data['tickets']));
  }

  void _reload() => setState(() => _future = _load());

  static const _fa = {
    'forex': 'فارکس',
    'metals': 'فلزات',
    'energy': 'انرژی',
    'crypto': 'کریپتو',
    'active': 'فعال',
    'rejected': 'ردشده',
    'pending_payment': 'در انتظار پرداخت',
    'pending': 'در انتظار',
    'open': 'باز',
    'closed': 'بسته',
    'answered': 'پاسخ داده شد',
  };
  String _t(String s) => _fa[s] ?? s;

  Color _statusColor(String s, Color fallback) {
    switch (s) {
      case 'active':
      case 'answered':
        return const Color(0xFF2E9E4F);
      case 'rejected':
      case 'closed':
        return const Color(0xFFD64545);
      case 'pending':
      case 'pending_payment':
      case 'open':
        return const Color(0xFFE8890C);
      default:
        return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiScope.of(context);
    final p = context.pal;
    return FutureBuilder<_Dash>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingView();
        if (snap.hasError) {
          final e = snap.error;
          if (e is ApiException && e.isInvalidToken) return const LoadingView();
          return ErrorView(error: e!, onRetry: _reload);
        }
        final d = snap.data!;
        final u = d.user;
        final shownName = u.name.isNotEmpty ? u.name : u.username;
        final initial = (shownName.isNotEmpty ? shownName : u.email).trim();
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          children: [
            // پروفایل
            _box(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [p.primary, p.secondary]),
                    ),
                    child: Text(initial.isEmpty ? '?' : initial.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shownName.isNotEmpty ? shownName : 'کاربر', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(u.email, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12, color: AppInk.muted)),
                        if (u.lastLogin != null) ...[
                          const SizedBox(height: 4),
                          Text('آخرین ورود: ${faDateTime(u.lastLogin)}', style: const TextStyle(fontSize: 11, color: AppInk.muted)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // موجودی
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [p.primary, p.secondary]),
                boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 18, color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 6),
                      Text('موجودی کیف پول', style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(toFa(formatToman(u.balance)), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.18), foregroundColor: Colors.white, minimumSize: const Size(0, 44)),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChargeScreen())),
                      icon: const Icon(Icons.add_card_rounded, size: 19),
                      label: const Text('شارژ کیف پول'),
                    ),
                  ),
                ],
              ),
            ),
            // کلیدهای API
            _section(
              icon: Icons.vpn_key_rounded,
              title: 'کلیدهای API',
              count: d.keys.length,
              empty: d.keys.isEmpty,
              children: [
                for (final m in d.keys) _row((m['label'] ?? 'بدون نام').toString(), null, chip: _t((m['calendar_type'] ?? '').toString()), chipColor: p.primary),
              ],
            ),
            // تیکت‌ها
            _section(
              icon: Icons.confirmation_number_rounded,
              title: 'تیکت‌ها',
              count: d.tickets.length,
              empty: d.tickets.isEmpty,
              children: [
                for (final m in d.tickets)
                  _row((m['subject'] ?? '').toString(), (m['ticket_code'] ?? '').toString(),
                      chip: _t((m['status'] ?? '').toString()), chipColor: _statusColor((m['status'] ?? '').toString(), p.primary)),
              ],
              action: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TicketsScreen(email: u.email))).then((_) => _reload()),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('تیکت جدید'),
              ),
            ),
            // تبلیغ‌ها
            _section(
              icon: Icons.campaign_rounded,
              title: 'تبلیغ‌ها',
              count: d.ads.length,
              empty: d.ads.isEmpty,
              children: [
                for (final m in d.ads)
                  _row((m['brand_name'] ?? m['title'] ?? 'تبلیغ').toString(), _t((m['page_target'] ?? '').toString()),
                      chip: _t((m['status'] ?? '').toString()), chipColor: _statusColor((m['status'] ?? '').toString(), p.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded, size: 19), label: const Text('به‌روزرسانی')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 46), foregroundColor: const Color(0xFFD64545), backgroundColor: const Color(0xFFD64545).withValues(alpha: 0.1)),
                    onPressed: () => api.logout(),
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    label: const Text('خروج'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _box({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppInk.line)),
        child: child,
      );

  Widget _section({
    required IconData icon,
    required String title,
    required int count,
    required bool empty,
    required List<Widget> children,
    Widget? action,
  }) {
    final p = context.pal;
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 18, color: p.primary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(10)),
                  child: Text(toFa(count), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.primary)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (empty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('موردی ثبت نشده', style: TextStyle(fontSize: 12, color: AppInk.muted))),
          ...children,
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }

  Widget _row(String title, String? sub, {String chip = '', Color chipColor = AppInk.muted}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppInk.line, width: 0.8))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                if (sub != null && sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 11, color: AppInk.muted)),
              ],
            ),
          ),
          if (chip.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: chipColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(chip, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: chipColor)),
            ),
        ],
      ),
    );
  }
}

class _Dash {
  const _Dash(this.user, this.keys, this.ads, this.tickets);
  final UserProfile user;
  final List<Map<String, dynamic>> keys;
  final List<Map<String, dynamic>> ads;
  final List<Map<String, dynamic>> tickets;
}
