import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';

/// صفحهٔ داخلی «شارژ» — فعلاً خالی (بدون درگاه یا لینک بیرونی).
class ChargeScreen extends StatelessWidget {
  const ChargeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      appBar: const BrandAppBar(subtitle: 'شارژ'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.account_balance_wallet_outlined, size: 38, color: p.primary),
            ),
            const SizedBox(height: 14),
            const Text('شارژ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
