import 'package:flutter/material.dart';

import '../../screens/login_screen.dart';
import '../../widgets/api_scope.dart';
import '../../widgets/state_views.dart';
import '../models.dart';
import '../sales_api.dart' show SalesApiException, salesErrorText;
import '../sales_state.dart';
import 'plans_screen.dart' show calendarTypesFa;

/// Plan detail + purchase confirm. Uses `GET /wallet` balance and `POST /subscriptions/purchase`.
class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({super.key, required this.state, required this.plan});
  final SalesState state;
  final Plan plan;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  bool _preparedForPurchase = false;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // After login on this screen, load wallet + mint Idempotency-Key once.
    if (ApiScope.of(context).isLoggedIn && !_preparedForPurchase) {
      _preparedForPurchase = true;
      widget.state.loadWallet();
      widget.state.beginPurchaseAttempt(widget.plan.id);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _buy() async {
    final s = widget.state;
    // Reuse Idempotency-Key on retry of the same attempt; only mint a new one
    // when starting a fresh attempt for this plan.
    if (s.purchasePlanId != widget.plan.id || s.purchaseIdempotencyKey == null) {
      s.beginPurchaseAttempt(widget.plan.id);
    }
    final result = await s.purchase(widget.plan.id);
    if (!mounted) return;
    if (result != null) {
      final name = result.plan.displayName.isNotEmpty
          ? result.plan.displayName
          : widget.plan.displayName;
      final price = result.subscription.pricePaidToman > 0
          ? result.subscription.pricePaidToman
          : widget.plan.priceToman;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            purchaseSuccessMessage(
              nameFa: name,
              priceToman: price,
              balanceAfter: result.balance,
              idempotent: result.idempotent,
            ),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      Navigator.of(context).pop(true);
    } else if (s.purchaseError != null) {
      final e = s.purchaseError!;
      final msg = salesErrorText(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    final s = widget.state;
    final balance = s.wallet?.balance;
    final insufficient = balance != null && balance < p.priceToman;
    final loggedIn = ApiScope.of(context).isLoggedIn;
    final canBuy = loggedIn && !s.purchasing && !insufficient && balance != null;

    return Scaffold(
      appBar: AppBar(title: Text(p.displayName), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(p.displayName, style: Theme.of(context).textTheme.headlineSmall),
          if (p.descriptionFa != null && p.descriptionFa!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.descriptionFa!),
          ],
          const SizedBox(height: 16),
          _row('قیمت', formatPlanPrice(p.priceToman)),
          _row(
            'مدت',
            p.durationDays == 30
                ? 'ماهانه (۳۰ روز)'
                : '${toPersianDigits('${p.durationDays}')} روز',
          ),
          if (p.calendarTypes.isNotEmpty) _row('تقویم‌ها', calendarTypesFa(p.calendarTypes)),
          _row(
            'سقف روزانه',
            p.dailyRequestLimit == null ? 'نامحدود' : toPersianDigits('${p.dailyRequestLimit}'),
          ),
          _row(
            'سقف ماهانه',
            p.monthlyRequestLimit == null ? 'نامحدود' : toPersianDigits('${p.monthlyRequestLimit}'),
          ),
          _row('محدودیت در دقیقه', toPersianDigits('${p.rateLimitPerMin}')),
          const Divider(height: 32),
          if (!ApiScope.of(context).isLoggedIn) ...[
            Text(
              'برای خرید این پلن وارد حساب شوید.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'شارژ کیف‌پول در حال حاضر فقط از طریق پشتیبانی انجام می‌شود.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 360, child: LoginScreen()),
          ] else if (s.loadingWallet && s.wallet == null)
            const LoadingView(label: 'در حال دریافت موجودی کیف‌پول…')
          else if (s.walletError != null && s.wallet == null)
            salesLoadErrorView(s.walletError!, s.loadWallet)
          else ...[
            _row('موجودی کیف‌پول', formatToman(balance ?? 0)),
            if (insufficient) ...[
              const SizedBox(height: 12),
              Text(
                'موجودی کافی نیست',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'برای خرید این پلن موجودی کیف پولتان کم است. لطفاً از پشتیبانی شارژ حساب بگیرید و دوباره تلاش کنید.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 4),
              const SelectableText('تماس با پشتیبانی — support@forexfactoryiran.ir'),
            ],
            const SizedBox(height: 12),
            Text(
              'شارژ کیف‌پول در حال حاضر فقط از طریق پشتیبانی انجام می‌شود.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'پس از خرید، لغو و تمدید از بخش «اشتراک‌ها» انجام می‌شود.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (s.purchaseError is SalesApiException) ...[
              const SizedBox(height: 12),
              Text(
                (s.purchaseError as SalesApiException).displayMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: canBuy ? _buy : null,
              icon: s.purchasing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shopping_cart_checkout),
              label: Text(
                s.purchasing
                    ? 'در حال ثبت خرید…'
                    : (insufficient ? 'موجودی کافی نیست' : 'تأیید و خرید'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w500))),
            Text(v),
          ],
        ),
      );
}
