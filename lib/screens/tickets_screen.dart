import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key, required this.email});
  final String email;
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _done;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().length < 10) {
      setState(() => _done = 'عنوان و حداقل ۱۰ حرف متن لازم است');
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await http.post(Uri.parse('https://forexfactoryiran.ir/api/public/app-panel.php'), body: {
        'email': widget.email,
        'subject': _title.text.trim(),
        'message': _body.text.trim(),
      });
      final data = jsonDecode(res.body);
      setState(() => _done = data['ok'] == true ? 'ثبت شد: ${data['code']}' : 'ثبت نشد');
      if (data['ok'] == true) {
        _title.clear();
        _body.clear();
      }
    } catch (_) {
      setState(() => _done = 'ارتباط برقرار نشد');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final ok = _done != null && _done!.startsWith('ثبت شد');
    return Scaffold(
      appBar: const BrandAppBar(subtitle: 'تیکت جدید'),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppInk.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _title, decoration: const InputDecoration(labelText: 'عنوان', prefixIcon: Icon(Icons.title_rounded))),
                const SizedBox(height: 12),
                TextField(controller: _body, minLines: 6, maxLines: 9, decoration: const InputDecoration(labelText: 'متن', alignLabelWithHint: true)),
                if (_done != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (ok ? p.accent : Theme.of(context).colorScheme.error).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_done!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send_rounded, size: 19),
                  label: Text(_busy ? '...' : 'ثبت تیکت'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
