import 'package:flutter/material.dart';

import '../../widgets/state_views.dart';
import '../models.dart';
import '../sales_state.dart';
import 'plan_detail_screen.dart';

const calendarTypeLabels = {
  'forex': 'فارکس',
  'metals': 'فلزات',
  'energy': 'انرژی',
  'crypto': 'کریپتو',
};

String calendarTypesFa(List<String> types) =>
    types.map((t) => calendarTypeLabels[t] ?? t).join('، ');

String _planSubtitle(Plan p) {
  final price = formatPlanPrice(p.priceToman);
  final dur = p.durationDays == 30
      ? 'ماهانه (۳۰ روز)'
      : '${toPersianDigits('${p.durationDays}')} روز';
  final cal =
      p.calendarTypes.isEmpty ? '' : ' · ${calendarTypesFa(p.calendarTypes)}';
  return '$price · $dur$cal';
}


/// Plans catalog (`GET /plans`). Empty state when all plans are inactive.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key, required this.state});
  final SalesState state;

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onChange);
    widget.state.loadPlans();
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
    if (s.loadingPlans && s.plans.isEmpty) {
      return const LoadingView(label: 'در حال بارگذاری پلن‌ها…');
    }
    if (s.plansError != null && s.plans.isEmpty) {
      return salesLoadErrorView(s.plansError!, s.loadPlans);
    }
    if (s.plans.isEmpty) {
      // 200 + plans:[] (inactive catalog) — distinct from 404 SalesComingSoonView above
      return RefreshIndicator(
        onRefresh: s.loadPlans,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 48),
            PlansInactiveEmptyView(onRetry: s.loadPlans),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: s.loadPlans,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: s.plans.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final p = s.plans[i];
          return Card(
            child: ListTile(
              title: Text(p.displayName),
              subtitle: Text(_planSubtitle(p)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () async {
                final purchased = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => PlanDetailScreen(state: s, plan: p),
                  ),
                );
                if (purchased == true && context.mounted) {
                  s.requestTab(SalesState.tabSubscriptions);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
