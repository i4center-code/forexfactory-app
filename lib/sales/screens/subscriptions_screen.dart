import 'package:flutter/material.dart';

import '../../utils/tehran_time.dart';
import '../../widgets/state_views.dart';
import '../models.dart';
import '../sales_api.dart' show salesErrorText;
import '../sales_state.dart';
import 'plans_screen.dart' show calendarTypesFa;

/// User subscriptions (`GET /subscriptions`) + cancel / renew (CANCEL_RENEW.md).
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key, required this.state});
  final SalesState state;

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onChange);
    widget.state.loadSubscriptions();
  }

  @override
  void dispose() {
    widget.state.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmCancel(Subscription sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('لغو اشتراک؟'),
        content: const Text(
          'اشتراک لغو می‌شود و کلیدهای API همین اشتراک از کار می‌افتند. '
          'وجه پرداخت‌شده برنمی‌گردد. این کار قابل بازگشت نیست مگر دوباره پلن بخرید.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('لغو اشتراک'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await widget.state.cancelSubscription(sub.id);
    if (!mounted) return;
    if (result != null) {
      final msg = result.idempotent
          ? 'این اشتراک از قبل لغو شده بود.'
          : 'اشتراک لغو شد'
              '${result.keysRevoked > 0 ? '؛ ${toPersianDigits('${result.keysRevoked}')} کلید باطل شد' : ''}.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else if (widget.state.subscriptionActionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(salesErrorText(widget.state.subscriptionActionError!))),
      );
    }
  }

  Future<void> _confirmRenew(Subscription sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تمدید اشتراک؟'),
        content: Text(
          'مبلغ پلن از کیف‌پولتان کسر می‌شود و تاریخ انقضا به اندازهٔ مدت پلن جلو می‌رود. '
          'قیمت تقریبی آخرین خرید: ${formatPlanPrice(sub.pricePaidToman)}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأیید تمدید'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    // Fresh Idempotency-Key per confirmed renew attempt (reuse only on automatic retry).
    widget.state.beginRenewAttempt(sub.id);
    final result = await widget.state.renewSubscription(sub.id);
    if (!mounted) return;
    if (result != null) {
      final until = result.subscription.expiresAt != null
          ? TehranTime.date(result.subscription.expiresAt)
          : '—';
      final msg = result.idempotent
          ? 'تمدید قبلاً ثبت شده بود؛ تا $until.'
          : 'اشتراک تمدید شد؛ تا $until. موجودی: ${formatToman(result.balance)}.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else if (widget.state.subscriptionActionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(salesErrorText(widget.state.subscriptionActionError!))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    if (!s.isLoggedIn) {
      return const EmptyView(text: 'برای مشاهده اشتراک‌ها وارد شوید');
    }
    if (s.loadingSubscriptions && s.subscriptions.isEmpty) {
      return const LoadingView(label: 'در حال بارگذاری اشتراک‌ها…');
    }
    if (s.subscriptionsError != null && s.subscriptions.isEmpty) {
      return salesLoadErrorView(s.subscriptionsError!, s.loadSubscriptions);
    }
    if (s.subscriptions.isEmpty) {
      return RefreshIndicator(
        onRefresh: s.loadSubscriptions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            EmptyView(text: 'اشتراک فعالی ندارید. از فهرست پلن‌ها یکی را بخرید.'),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: s.loadSubscriptions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: s.subscriptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final sub = s.subscriptions[i];
          final busy = s.lifecycleBusySubId == sub.id;
          return Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text('پلن #${toPersianDigits('${sub.planId}')} — ${sub.statusLabelFa}'),
                    subtitle: Text(
                      [
                        formatPlanPrice(sub.pricePaidToman),
                        if (sub.calendarTypes.isNotEmpty) calendarTypesFa(sub.calendarTypes),
                        if (sub.startsAt != null) 'از ${TehranTime.date(sub.startsAt)}',
                        if (sub.expiresAt != null) 'تا ${TehranTime.date(sub.expiresAt)}',
                      ].join(' · '),
                    ),
                    leading: Icon(
                      sub.isActive ? Icons.check_circle : Icons.cancel_outlined,
                      color: sub.isActive ? Colors.green : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (sub.canRenew)
                          OutlinedButton.icon(
                            onPressed: busy ? null : () => _confirmRenew(sub),
                            icon: busy && s.renewingSubscription
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.autorenew, size: 18),
                            label: Text(busy && s.renewingSubscription ? 'در حال تمدید…' : 'تمدید'),
                          ),
                        if (sub.canCancel)
                          OutlinedButton.icon(
                            onPressed: busy ? null : () => _confirmCancel(sub),
                            icon: busy && s.cancellingSubscription
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.cancel_outlined, size: 18),
                            label: Text(busy && s.cancellingSubscription ? 'در حال لغو…' : 'لغو'),
                          ),
                        if (sub.isCancelled)
                          Text(
                            'لغو شده — برای ادامه از فهرست پلن‌ها بخرید.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
