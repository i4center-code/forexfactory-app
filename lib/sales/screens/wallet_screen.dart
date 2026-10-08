import 'package:flutter/material.dart';

import '../../utils/tehran_time.dart';
import '../../widgets/state_views.dart';
import '../models.dart';
import '../sales_state.dart';

/// Wallet balance + ledger (`GET /wallet`).
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, required this.state});
  final SalesState state;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onChange);
    widget.state.loadWallet();
  }

  @override
  void dispose() {
    widget.state.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    if (!s.isLoggedIn) {
      return const EmptyView(text: 'برای مشاهده کیف‌پول وارد شوید');
    }
    if (s.loadingWallet && s.wallet == null) return const LoadingView();
    if (s.walletError != null && s.wallet == null) {
      return salesLoadErrorView(s.walletError!, s.loadWallet);
    }
    final w = s.wallet!;
    return RefreshIndicator(
      onRefresh: s.loadWallet,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('موجودی', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    formatToman(w.balance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'شارژ کیف‌پول در حال حاضر فقط از طریق پشتیبانی انجام می‌شود.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text('گردش حساب', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (w.ledger.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyView(text: 'هنوز تراکنشی در کیف‌پول ثبت نشده است.'),
            )
          else
            for (final e in w.ledger) _LedgerTile(entry: e),
        ],
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});
  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final positive = entry.amountToman >= 0;
    final color = positive ? Colors.green.shade700 : Theme.of(context).colorScheme.error;
    return Card(
      child: ListTile(
        title: Text(entry.typeLabelFa),
        subtitle: Text(
          [
            if (entry.description != null && entry.description!.isNotEmpty) entry.description!,
            if (entry.createdAt != null) TehranTime.dateTime(entry.createdAt),
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
        trailing: Text(
          formatToman(entry.amountToman),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
