import 'package:flutter/material.dart';

import '../api/api_client.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'در حال بارگذاری…'});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(height: 14),
            Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7488))),
          ],
        ),
      );
}

/// True when sales/data routes are missing on the API host (live pre-deploy 404).
/// Does **not** treat `user_not_found` / `invalid_type` as undeployed.
bool isSalesNotDeployed(Object? error) {
  if (error is! ApiException) return false;
  final e = error;
  if (e.code == 'user_not_found' || e.code == 'invalid_type') return false;
  return e.isNotFound || e.statusCode == 404 || e.code == 'not_found';
}


/// GET /plans returned 200 with empty list (all plans inactive) — not a deploy 404.
class PlansInactiveEmptyView extends StatelessWidget {
  const PlansInactiveEmptyView({super.key, this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'فروش پلن‌های API به‌زودی',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'هنوز پلنی برای خرید فعال نشده. به‌محض فعال‌سازی از طرف ما، اینجا فهرست پلن‌ها را می‌بینید.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shared empty state when `/plans`, `/wallet`, `/keys`, `/subscriptions` are not deployed yet.
class SalesComingSoonView extends StatelessWidget {
  const SalesComingSoonView({
    super.key,
    required this.onRetry,
    this.title = 'به‌زودی',
    this.message = 'فروش API هنوز فعال نشده — به‌زودی اینجا می‌آید.',
  });

  final VoidCallback onRetry;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Routes 404/not_found (undeployed sales) to [SalesComingSoonView]; other errors to [ErrorView].
Widget salesLoadErrorView(Object error, VoidCallback onRetry) {
  if (isSalesNotDeployed(error)) {
    return SalesComingSoonView(onRetry: onRetry);
  }
  return ErrorView(error: error, onRetry: onRetry);
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    String msg;
    var isNet = false;
    IconData icon = Icons.error_outline;
    if (error is ApiException) {
      final e = error as ApiException;
      msg = e.displayMessage;
      isNet = e.isNetwork;
      if (e.isInsufficientBalance) icon = Icons.account_balance_wallet_outlined;
      if (e.isRateLimited) icon = Icons.hourglass_top;
      if (e.isForbidden) icon = Icons.lock_outline;
      if (e.isConflict) icon = Icons.report_gmailerrorred_outlined;
      if (e.isNotFound) icon = Icons.search_off;
      if (isNet) icon = Icons.wifi_off;
    } else {
      msg = 'ارتباط برقرار نشد. اتصال اینترنت را چک کنید و دوباره تلاش کنید.';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: Theme.of(context).colorScheme.error.withValues(alpha: 0.85)),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center),
            if (isNet) ...[
              const SizedBox(height: 8),
              Text(
                'اگر روی وب اجرا می‌کنید، ممکن است محدودیت CORS باشد؛ اتصال یا تنظیمات سرور را بررسی کنید.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('تلاش مجدد')),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7488))),
          ],
        ),
      );
}
