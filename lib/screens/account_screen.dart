import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../app_version.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import '../sales/format.dart';
import '../sales/sales_api.dart';
import '../sales/sales_api.dart' show salesErrorText;
import '../sales/sales_state.dart';
import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import '../widgets/api_scope.dart';
import '../widgets/site_header.dart';
import '../widgets/state_views.dart';
import 'charge_screen.dart';
import 'login_screen.dart';
import 'tickets_screen.dart';

/// صفحهٔ «حساب» با هدر سایت و دکمهٔ برگشت.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SiteHeader(section: 'account', onSection: (_) {}, showBack: true, backLabel: 'حساب کاربری'),
          Expanded(child: api.isLoggedIn ? const _ProfileView() : const LoginScreen()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text('نسخه ${toFa(kAppVersion, decimal: false)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppInk.muted)),
          ),
        ],
      ),
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
    final res = await http
        .get(Uri.parse('https://forexfactoryiran.ir/api/public/app-panel.php?email=${Uri.encodeComponent(me.email)}'))
        .timeout(const Duration(seconds: 15));
    final data = res.statusCode == 200 ? jsonDecode(utf8.decode(res.bodyBytes)) : <String, dynamic>{};
    List<Map<String, dynamic>> list(dynamic v) => v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    // اشتراک‌های API (برای شمارۀ صحیح کلیدها) — در صورت خطا نادیده گرفته می‌شود
    List<Subscription> subs = [];
    try {
      subs = await SalesApi(api).getSubscriptions();
    } catch (_) {}
    return _Dash(me, list(data['keys']), list(data['ads']), list(data['tickets']), subs);
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
    'expired': 'منقضی',
    'cancelled': 'لغوشده',
  };
  String _t(String s) => _fa[s] ?? s;

  Color _statusColor(String s, Color fallback) {
    switch (s) {
      case 'active':
      case 'answered':
        return const Color(0xFF2E9E4F);
      case 'rejected':
      case 'closed':
      case 'expired':
        return const Color(0xFFD64545);
      case 'pending':
      case 'pending_payment':
      case 'open':
      case 'cancelled':
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
          if (e is ApiException && e.isInvalidToken) return const LoginScreen();
          return ErrorView(error: e!, onRetry: _reload);
        }
        final d = snap.data!;
        final u = d.user;
        final shownName = u.name.isNotEmpty ? u.name : u.username;
        final initial = (shownName.isNotEmpty ? shownName : u.email).trim();
        final activeSubs = d.subscriptions.where((m) => (m.status ?? '') == 'active').length;
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
                    child: Text(
                      initial.isEmpty ? '?' : String.fromCharCode(initial.runes.first).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
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
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.18), foregroundColor: Colors.white, minimumSize: const Size(0, 44)),
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChargeScreen())),
                          icon: const Icon(Icons.add_card_rounded, size: 19),
                          label: const Text('شارژ کیف پول'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.12), foregroundColor: Colors.white, minimumSize: const Size(0, 44)),
                          onPressed: () => _showPlans(context),
                          icon: const Icon(Icons.storefront_rounded, size: 19),
                          label: const Text('پلن‌های API'),
                        ),
                      ),
                    ],
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
              action: OutlinedButton.icon(
                onPressed: () => _showPlans(context),
                icon: const Icon(Icons.key_rounded, size: 18),
                label: Text(activeSubs > 0 ? 'ساخت / مدیریت کلیدها' : 'خرید پلن برای ساخت کلید'),
              ),
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
                icon: const Icon(Icons.list_alt_rounded, size: 19),
                label: const Text('لیست و پیگیری تیکت‌ها'),
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

  /// خرید پلن + ساخت/مدیریت کلید API — همان ماژول sales ریپازیتوری،
  /// داخل دیالوگ تا هدر سایت حفظ شود.
  void _showPlans(BuildContext context) {
    final p = context.pal;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: Material(
            color: p.tint,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: const _SalesSheet(),
          ),
        ),
      ),
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
  const _Dash(this.user, this.keys, this.ads, this.tickets, this.subscriptions);
  final UserProfile user;
  final List<Map<String, dynamic>> keys;
  final List<Map<String, dynamic>> ads;
  final List<Map<String, dynamic>> tickets;
  final List<Subscription> subscriptions;
}

class _SalesSheet extends StatefulWidget {
  const _SalesSheet();

  @override
  State<_SalesSheet> createState() => _SalesSheetState();
}

class _SalesSheetState extends State<_SalesSheet> {
  SalesState? _st;
  int _tab = 0; // 0 plans | 1 keys

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_st == null) {
      _st = SalesState(SalesApi(ApiScope.read(context)));
      _st!.addListener(_onState);
      _st!.loadPlans();
      _st!.refreshAllAuthed();
    }
  }

  void _onState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _st?.removeListener(_onState);
    _st?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = _st!;
    final p = context.pal;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Icon(Icons.storefront_rounded, size: 20, color: p.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('پلن‌ها و کلید API', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.primary))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              _pill('پلن‌ها', Icons.local_offer_outlined, 0, p, st),
              const SizedBox(width: 8),
              _pill('کلیدهای من', Icons.vpn_key_rounded, 1, p, st),
            ],
          ),
        ),
        Divider(height: 1, color: AppInk.line),
        Expanded(child: _tab == 0 ? _plans(st, p) : _keys(st, p)),
      ],
    );
  }

  Widget _pill(String label, IconData icon, int i, AppPalette p, SalesState st) {
    final sel = _tab == i;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: sel ? p.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? p.primary : AppInk.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: sel ? Colors.white : p.primary),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sel ? Colors.white : p.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plans(SalesState st, AppPalette p) {
    if (!st.isLoggedIn) return _needLogin(p);
    if (st.loadingPlans && st.plans.isEmpty) return const LoadingView(label: 'خواندن پلن‌ها…');
    if (st.plansError != null && st.plans.isEmpty) return salesLoadErrorView(st.plansError!, () => st.loadPlans());
    if (st.plans.isEmpty) return const PlansInactiveEmptyView();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      children: [
        if (st.wallet != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppInk.line)),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 18, color: p.primary),
                const SizedBox(width: 8),
                const Text('موجودی:', style: TextStyle(fontSize: 12.5, color: AppInk.muted)),
                const SizedBox(width: 6),
                Text(toFa(formatToman(st.wallet!.balance)), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.primary)),
                const Spacer(),
                if (st.purchasing || st.loadingWallet) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
        if (st.purchaseError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFD64545).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Text(salesErrorText(st.purchaseError!), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFB03030))),
          ),
        for (final plan in st.plans)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppInk.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(plan.nameFa, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                    Text(toFa(formatPlanPrice(plan.priceToman)), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.primary)),
                  ],
                ),
                if ((plan.descriptionFa ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(plan.descriptionFa!, style: const TextStyle(fontSize: 11.5, color: AppInk.muted, height: 1.7)),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in plan.calendarTypes) _tag(kCalendarShort[t] ?? t, p),
                    if (plan.durationDays > 0) _tag('${toFa(plan.durationDays)} روز', p),
                    if (plan.dailyRequestLimit != null) _tag('${toFa(plan.dailyRequestLimit!)} درخواست/روز', p),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                  onPressed: st.purchasing ? null : () => _buy(st, plan.id),
                  icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                  label: Text(st.purchasing && st.purchasePlanId == plan.id ? 'در حال خرید…' : 'خرید با کیف پول'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _keys(SalesState st, AppPalette p) {
    if (!st.isLoggedIn) return _needLogin(p);
    final activeSubs = st.subscriptions.where((s) => s.status == 'active').toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      children: [
        if (st.keysError != null)
          isSalesNotDeployed(st.keysError!)
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('فروش API هنوز روی سرور فعال نشده است.', style: TextStyle(fontSize: 12.5, color: AppInk.muted))),
                )
              : Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFD64545).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Text(salesErrorText(st.keysError!), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFB03030))),
                ),
        if (st.keyActionError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFD64545).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Text(salesErrorText(st.keyActionError!), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFB03030))),
          ),
        if (activeSubs.isEmpty && st.subscriptionsError == null && !st.loadingSubscriptions)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: p.tint, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppInk.line)),
            child: const Text('برای ساخت کلید API اول یک پلن را از تب «پلن‌ها» بخرید.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppInk.muted)),
          ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: (st.creatingKey || activeSubs.isEmpty) ? null : () => _createKey(st),
          icon: st.creatingKey
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add_key_rounded, size: 19),
          label: Text(st.creatingKey ? '…' : 'ساخت کلید جدید'),
        ),
        const SizedBox(height: 14),
        if (st.keys.isEmpty && !st.loadingKeys)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('هنوز کلیدی نساخته‌اید', style: TextStyle(fontSize: 12.5, color: AppInk.muted))),
          ),
        for (final k in st.keys)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: k.status == 'active' ? AppInk.line : const Color(0xFFD64545).withValues(alpha: 0.4))),
            child: Row(
              children: [
                Icon(k.status == 'active' ? Icons.key_rounded : Icons.key_off_rounded, size: 17, color: k.status == 'active' ? p.primary : const Color(0xFFD64545)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k.name.isNotEmpty ? k.name : 'کلید ${toFa(k.id)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(k.display, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 11, color: AppInk.muted)),
                      if (k.lastUsedAt != null) Text('آخرین استفاده: ${faDateTime(k.lastUsedAt)}', style: const TextStyle(fontSize: 10.5, color: AppInk.muted)),
                    ],
                  ),
                ),
                if (k.status == 'active')
                  TextButton(
                    onPressed: st.revokingKey ? null : () => st.revokeKey(k.id),
                    child: const Text('ابطال', style: TextStyle(color: Color(0xFFD64545), fontSize: 12)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFD64545).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('باطل‌شده', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD64545))),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _needLogin(AppPalette p) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 42, color: p.primary.withValues(alpha: 0.7)),
              const SizedBox(height: 12),
              const Text('برای خرید پلن و ساخت کلید، اول وارد حساب شوید.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppInk.muted)),
            ],
          ),
        ),
      );

  Future<void> _buy(SalesState st, int planId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید خرید'),
        content: const Text('مبلغ از کیف پول کسر و پلن فعال می‌شود. ادامه می‌دهید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('خرید')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await st.purchase(planId);
    if (res != null && mounted) {
      setState(() => _tab = 1);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خرید انجام شد — حالا می‌توانید کلید API بسازید.')));
    }
  }

  Future<void> _createKey(SalesState st) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('کلید API جدید'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'نام کلید (اختیاری)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('ساخت')),
        ],
      ),
    );
    if (name == null) return;
    final res = await st.createKey(name: name.isEmpty ? null : name);
    if (res != null && mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('کلید شما — فقط همین یک‌بار نمایش داده می‌شود'),
          content: SelectableText(res.apiKey, textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('کپی شد / ببند'))],
        ),
      );
    }
  }

  Widget _tag(String text, AppPalette p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.primary)),
      );
}
