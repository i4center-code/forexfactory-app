import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/tehran_time.dart';
import '../../widgets/state_views.dart';
import '../models.dart';
import '../sales_api.dart' show salesErrorText;
import '../sales_state.dart';


/// QUOTA_NOTES — confirm before DELETE /keys/{id}
const kRevokeKeyDialogTitle = 'باطل کردن کلید API؟';
const kRevokeKeyConfirmLabel = 'باطل کردن کلید';
const kRevokeKeyCancelLabel = 'انصراف';
const kRevokeKeySuccessSnack =
    'کلید باطل شد. در صورت نیاز از فهرست کلیدها، کلید تازه بسازید.';
const kRawKeyCopiedSnack =
    'کلید کپی شد — فقط همین یک‌بار آن را می‌بینید؛ جای امن نگه دارید.';

String revokeKeyDialogBody(String keyLabel) =>
    'کلید «$keyLabel» دیگر کار نمی‌کند و برنامه‌هایی که از آن استفاده می‌کنند قطع می‌شوند. '
    'این کار برگشت‌پذیر نیست؛ در صورت نیاز باید کلید جدید بسازید '
    '(کلید خام فقط یک‌بار نشان داده می‌شود).';

String revokeKeyLabel(ApiKey key) {
  if (key.display.isNotEmpty) return key.display;
  if (key.keyPrefix.isNotEmpty || key.keyLast4.isNotEmpty) {
    return '${key.keyPrefix}…${key.keyLast4}';
  }
  return '#${key.id}';
}

/// Testable dialog builder (QUOTA_NOTES wording).
Widget buildRevokeKeyConfirmDialog({
  required BuildContext context,
  required String keyLabel,
  required VoidCallback onCancel,
  required VoidCallback onConfirm,
}) {
  return AlertDialog(
    title: const Text(kRevokeKeyDialogTitle),
    content: Text(revokeKeyDialogBody(keyLabel)),
    actions: [
      TextButton(onPressed: onCancel, child: const Text(kRevokeKeyCancelLabel)),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        onPressed: onConfirm,
        child: const Text(kRevokeKeyConfirmLabel),
      ),
    ],
  );
}

/// API keys list / create / revoke (`GET|POST /keys`, `DELETE /keys/{id}`).
class KeysScreen extends StatefulWidget {
  const KeysScreen({super.key, required this.state});
  final SalesState state;

  @override
  State<KeysScreen> createState() => _KeysScreenState();
}

class _KeysScreenState extends State<KeysScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onChange);
    widget.state.loadKeys();
  }

  @override
  void dispose() {
    widget.state.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ساخت کلید API'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'نام (اختیاری)',
            border: OutlineInputBorder(),
            hintText: 'مثلاً سرور من',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('ساخت'),
          ),
        ],
      ),
    );
    // Dialog dismissed
    if (name == null || !mounted) return;

    final result = await widget.state.createKey(name: name.isEmpty ? null : name);
    if (!mounted) return;
    if (result != null) {
      // SalesApi.createKey already persists raw key locally via FfiApi.saveCreatedApiKey.
      await _showRawKeyDialog(result.apiKey);
    } else if (widget.state.keyActionError != null) {
      final e = widget.state.keyActionError!;
      final msg = salesErrorText(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _showRawKeyDialog(String raw) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('کلید API شما'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                raw,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'این کلید فقط یک‌بار نمایش داده می‌شود. آن را کپی و در جای امن ذخیره کنید؛ دیگر قابل مشاهده نیست.',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: raw));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text(kRawKeyCopiedSnack)),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('کپی'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(ApiKey key) async {
    final label = revokeKeyLabel(key);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => buildRevokeKeyConfirmDialog(
        context: ctx,
        keyLabel: label,
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok != true || !mounted) return;
    final success = await widget.state.revokeKey(key.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(kRevokeKeySuccessSnack)),
      );
    } else if (widget.state.keyActionError != null) {
      final e = widget.state.keyActionError!;
      final msg = salesErrorText(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    if (!s.isLoggedIn) {
      return const EmptyView(text: 'برای مدیریت کلیدها وارد شوید');
    }
    if (s.loadingKeys && s.keys.isEmpty) return const LoadingView();
    if (s.keysError != null && s.keys.isEmpty) {
      return salesLoadErrorView(s.keysError!, s.loadKeys);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: s.creatingKey ? null : _create,
        icon: s.creatingKey
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add),
        label: const Text('کلید جدید'),
      ),
      body: RefreshIndicator(
        onRefresh: s.loadKeys,
        child: s.keys.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyView(text: 'هنوز کلید API نساخته‌اید. با «کلید جدید» یکی بسازید؛ کلید خام فقط یک‌بار نشان داده می‌شود.'),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: s.keys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final k = s.keys[i];
                  return Card(
                    child: ListTile(
                      title: Text(
                        k.name.isNotEmpty ? k.name : k.display,
                        textDirection: k.name.isEmpty ? TextDirection.ltr : null,
                      ),
                      subtitle: Text(
                        [
                          if (k.name.isNotEmpty) k.display,
                          k.statusLabelFa,
                          if (k.createdAt != null) 'ایجاد: ${TehranTime.dateTime(k.createdAt)}',
                          if (k.lastUsedAt != null)
                            'آخرین استفاده: ${TehranTime.dateTime(k.lastUsedAt)}'
                          else
                            'هنوز استفاده نشده',
                        ].where((e) => e.toString().isNotEmpty).join('\n'),
                        textDirection: TextDirection.rtl,
                      ),
                      isThreeLine: true,
                      trailing: k.isActive
                          ? IconButton(
                              tooltip: 'باطل کردن کلید',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: s.revokingKey ? null : () => _revoke(k),
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
