import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../screens/paid_calendar_screen.dart';
import '../widgets/api_scope.dart';
import 'sales_api.dart';
import 'sales_state.dart';
import 'screens/keys_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/wallet_screen.dart';

/// Entry point for the API-sales section.
///
/// - **Plans** (`GET /plans`) are public — visible without login.
/// - Wallet / subscriptions / keys / purchase require login; those tabs show
///   [LoginScreen] when logged out.
///
/// Jafar already wires both the API bottom-nav tab and the account tile.
class SalesHomeScreen extends StatefulWidget {
  const SalesHomeScreen({super.key});

  @override
  State<SalesHomeScreen> createState() => _SalesHomeScreenState();
}

class _SalesHomeScreenState extends State<SalesHomeScreen> {
  SalesState? _state;
  int _tab = SalesState.tabPlans;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state == null) {
      _state = SalesState(SalesApi(ApiScope.read(context)));
      _state!.addListener(_onState);
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_onState);
    _state?.dispose();
    super.dispose();
  }

  void _onState() {
    final next = _state?.takeRequestedTab();
    if (next != null && mounted) {
      setState(() => _tab = next);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when auth changes so protected tabs flip between login / content.
    final loggedIn = ApiScope.of(context).isLoggedIn;
    final state = _state!;

    final pages = [
      PlansScreen(state: state),
      loggedIn ? WalletScreen(state: state) : const SalesLoginPrompt(
        message: 'برای مشاهده کیف‌پول و گردش حساب وارد شوید.',
      ),
      loggedIn ? SubscriptionsScreen(state: state) : const SalesLoginPrompt(
        message: 'برای مشاهده اشتراک‌ها وارد شوید.',
      ),
      loggedIn ? KeysScreen(state: state) : const SalesLoginPrompt(
        message: 'برای مدیریت کلیدهای API وارد شوید.',
      ),
    ];
    const titles = ['پلن‌ها', 'کیف‌پول', 'اشتراک‌ها', 'کلیدهای API'];

    return Column(
      children: [
        if (loggedIn)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaidCalendarScreen()),
                  );
                },
                icon: const Icon(Icons.lock_clock),
                label: const Text('تقویم پولی با کلید API'),
              ),
            ),
          ),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: _SalesTabBar(
            titles: titles,
            selected: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
        ),
        Expanded(child: pages[_tab]),
      ],
    );
  }
}

/// Compact login prompt used on protected sales tabs when logged out.
class SalesLoginPrompt extends StatelessWidget {
  const SalesLoginPrompt({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Icon(Icons.lock_outline, size: 36, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'شارژ کیف‌پول فعلاً از طریق پشتیبانی انجام می‌شود.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Expanded(child: LoginScreen()),
      ],
    );
  }
}

class _SalesTabBar extends StatelessWidget {
  const _SalesTabBar({
    required this.titles,
    required this.selected,
    required this.onSelect,
  });

  final List<String> titles;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < titles.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(titles[i]),
                selected: selected == i,
                onSelected: (_) => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-scaffold variant for a pushed route (account tile).
class SalesHomeRoute extends StatelessWidget {
  const SalesHomeRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فروش API'), centerTitle: true),
      body: const SalesHomeScreen(),
    );
  }
}
