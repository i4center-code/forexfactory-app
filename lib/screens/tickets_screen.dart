import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import '../widgets/site_header.dart';

/// تیکت کامل درون‌اپ با همان API موجود ریپازیتوری (app-panel.php):
/// - GET  ?email=...                → فهرست تیکت‌ها و پاسخ‌ها
/// - POST email+subject+message     → ساخت تیکت جدید (کد بازگشتی)
/// - POST email+ticket_code+message → پاسخ روی یک تیکت
class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key, required this.email});
  final String email;

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  static const _panel = 'https://forexfactoryiran.ir/api/public/app-panel.php';

  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http
          .get(Uri.parse('$_panel?email=${Uri.encodeComponent(widget.email)}'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('status ${res.statusCode}');
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final t = data is Map ? data['tickets'] : null;
      _tickets = t is List ? t.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    } catch (_) {
      _error = 'تیکت‌ها خوانده نشدند';
    }
    if (mounted) setState(() => _loading = false);
  }

  static String _s(dynamic v) => (v ?? '').toString();

  Map<String, dynamic> _normalize(Map<String, dynamic> m) {
    final repliesRaw = m['replies'] ?? m['messages'] ?? m['answers'];
    final replies = <Map<String, dynamic>>[];
    final single = m['reply'] ?? m['answer'];
    if (single != null) {
      if (single is Map) replies.add(Map<String, dynamic>.from(single.cast()));
      if (single is String && single.trim().isNotEmpty) replies.add({'message': single, 'date': null});
    }
    if (repliesRaw is List) {
      for (final e in repliesRaw.whereType<Map>()) {
        replies.add(Map<String, dynamic>.from(e.cast()));
      }
    } else if (repliesRaw is String && repliesRaw.trim().isNotEmpty) {
      replies.add({'message': repliesRaw, 'date': null});
    }
    return {
      'code': _s(m['ticket_code'] ?? m['code']),
      'subject': _s(m['subject'] ?? m['title']),
      'status': _s(m['status']),
      'date': m['date'] ?? m['created_at'],
      'message': _s(m['message'] ?? m['body']),
      'replies': replies,
    };
  }

  void _openDetail(Map<String, dynamic> ticket) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => _TicketDetail(email: widget.email, ticket: ticket, onReplied: _load)))
        .then((_) => _load());
  }

  void _compose() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => _NewTicket(email: widget.email, onCreated: _load)))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tickets = _tickets.map(_normalize).toList();
    return Scaffold(
      body: Column(
        children: [
          SiteHeader(section: 'account', onSection: (_) {}, showBack: true, backLabel: 'تیکت‌ها'),
          Expanded(
            child: RefreshIndicator(
              color: p.primary,
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            const Icon(Icons.wifi_off_rounded, size: 44, color: AppInk.muted),
                            const SizedBox(height: 10),
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppInk.muted)),
                            const SizedBox(height: 12),
                            Center(
                              child: OutlinedButton.icon(
                                  onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('تلاش مجدد')),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                          children: [
                            Row(
                              children: [
                                Icon(Icons.confirmation_number_rounded, size: 20, color: p.primary),
                                const SizedBox(width: 6),
                                Expanded(child: Text('تیکت‌های من', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.primary))),
                                FilledButton.icon(
                                  onPressed: _compose,
                                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('تیکت جدید'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (tickets.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 34),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppInk.line)),
                                child: const Column(
                                  children: [
                                    Icon(Icons.mail_outline_rounded, size: 40, color: AppInk.muted),
                                    SizedBox(height: 8),
                                    Text('هنوز تیکتی ثبت نکرده‌اید', style: TextStyle(fontSize: 13, color: AppInk.muted)),
                                  ],
                                ),
                              ),
                            for (final t in tickets) _ticketCard(t, p),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketCard(Map<String, dynamic> t, AppPalette p) {
    final status = t['status'].toString();
    final replies = (t['replies'] as List).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppInk.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(t),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.support_agent_rounded, size: 19, color: p.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['subject'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('کد ${toFa(t['code'].toString())} · ${faDate(t['date'])}', style: const TextStyle(fontSize: 11, color: AppInk.muted)),
                  ],
                ),
              ),
              if (replies > 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Chip(
                    label: Text('${toFa(replies)} پاسخ'),
                    labelStyle: const TextStyle(fontSize: 10.5),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: p.accent.withValues(alpha: 0.5)),
                  ),
                ),
              _StatusChip(status: status, palette: p),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.palette});
  final String status;
  final AppPalette palette;

  static const _labels = {'open': 'باز', 'pending': 'در انتظار', 'answered': 'پاسخ داده شد', 'closed': 'بسته'};

  Color get _color => switch (status) {
        'answered' => const Color(0xFF2E9E4F),
        'closed' => const Color(0xFFD64545),
        'open' || 'pending' => const Color(0xFFE8890C),
        _ => AppInk.muted,
      };

  @override
  Widget build(BuildContext context) {
    final col = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(_labels[status] ?? status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: col)),
    );
  }
}

/// مشاهدهٔ تیکت + پاسخ‌ها + پاسخ دادن (POST با ticket_code)
class _TicketDetail extends StatefulWidget {
  const _TicketDetail({required this.email, required this.ticket, required this.onReplied});
  final String email;
  final Map<String, dynamic> ticket;
  final VoidCallback onReplied;

  @override
  State<_TicketDetail> createState() => _TicketDetailState();
}

class _TicketDetailState extends State<_TicketDetail> {
  final _reply = TextEditingController();
  bool _busy = false;
  String? _note;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.length < 3) {
      setState(() => _note = 'متن پاسخ کوتاه است');
      return;
    }
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      final res = await http
          .post(
            Uri.parse('https://forexfactoryiran.ir/api/public/app-panel.php'),
            body: {'email': widget.email, 'ticket_code': widget.ticket['code'], 'message': text},
          )
          .timeout(const Duration(seconds: 15));
      final data = res.statusCode == 200 ? (jsonDecode(utf8.decode(res.bodyBytes)) as Map) : <String, dynamic>{};
      if (data['ok'] == true) {
        _reply.clear();
        widget.onReplied();
        if (mounted) setState(() => _note = 'پاسخ شما ثبت شد');
      } else if (mounted) {
        setState(() => _note = 'پاسخ ثبت نشد؛ دوباره تلاش کنید');
      }
    } catch (_) {
      if (mounted) setState(() => _note = 'ارتباط برقرار نشد');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = widget.ticket;
    final replies = (t['replies'] as List).cast<Map>();
    return Scaffold(
      body: Column(
        children: [
          SiteHeader(section: 'account', onSection: (_) {}, showBack: true, backLabel: 'تیکت ${toFa(t['code'].toString())}'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppInk.line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(t['subject'].toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                          _StatusChip(status: t['status'].toString(), palette: p),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('کد ${toFa(t['code'].toString())} · ${faDateTime(t['date'])}', style: const TextStyle(fontSize: 11.5, color: AppInk.muted)),
                      const Divider(height: 22),
                      Text(toFa(t['message'].toString()), style: const TextStyle(fontSize: 13.5, height: 1.9)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('پاسخ‌ها', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.primary)),
                const SizedBox(height: 8),
                if (replies.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppInk.line)),
                    child: const Center(child: Text('هنوز پاسخی ثبت نشده', style: TextStyle(fontSize: 12, color: AppInk.muted))),
                  ),
                for (final r in replies)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(p.accent.withValues(alpha: 0.06), Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.accent.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.support_agent_rounded, size: 16, color: p.secondary),
                            const SizedBox(width: 6),
                            Text('پشتیبانی', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.secondary)),
                            const Spacer(),
                            Text(faDateTime(r['date'] ?? r['created_at']), style: const TextStyle(fontSize: 10.5, color: AppInk.muted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(toFa((r['message'] ?? r['reply'] ?? '').toString()), style: const TextStyle(fontSize: 13, height: 1.9)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppInk.line)),
                  child: Column(
                    children: [
                      TextField(
                        controller: _reply,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(labelText: 'پاسخ شما…', alignLabelWithHint: true),
                      ),
                      if (_note != null) ...[
                        const SizedBox(height: 8),
                        Text(_note!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.primary)),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _send,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text(_busy ? '…' : 'ارسال پاسخ'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ساخت تیکت جدید (POST email+subject+message)
class _NewTicket extends StatefulWidget {
  const _NewTicket({required this.email, required this.onCreated});
  final String email;
  final VoidCallback onCreated;

  @override
  State<_NewTicket> createState() => _NewTicketState();
}

class _NewTicketState extends State<_NewTicket> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;
  String? _note;
  bool _ok = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = _subject.text.trim();
    final b = _body.text.trim();
    if (s.isEmpty || b.length < 10) {
      setState(() => _note = 'عنوان و حداقل ۱۰ حرف متن لازم است');
      return;
    }
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      final res = await http
          .post(Uri.parse('https://forexfactoryiran.ir/api/public/app-panel.php'), body: {
            'email': widget.email,
            'subject': s,
            'message': b,
          })
          .timeout(const Duration(seconds: 15));
      final data = res.statusCode == 200 ? (jsonDecode(utf8.decode(res.bodyBytes)) as Map) : <String, dynamic>{};
      if (data['ok'] == true) {
        widget.onCreated();
        setState(() {
          _ok = true;
          _note = 'تیکت ثبت شد — کد پیگیری: ${toFa((data['code'] ?? '').toString())}';
        });
        _subject.clear();
        _body.clear();
      } else {
        setState(() => _note = 'ثبت نشد؛ دوباره تلاش کنید');
      }
    } catch (_) {
      setState(() => _note = 'ارتباط برقرار نشد');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: Column(
        children: [
          SiteHeader(section: 'account', onSection: (_) {}, showBack: true, backLabel: 'تیکت جدید'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppInk.line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(controller: _subject, decoration: const InputDecoration(labelText: 'عنوان', prefixIcon: Icon(Icons.title_rounded))),
                      const SizedBox(height: 12),
                      TextField(controller: _body, minLines: 6, maxLines: 9, decoration: const InputDecoration(labelText: 'متن', alignLabelWithHint: true)),
                      if (_note != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_ok ? p.accent : Theme.of(context).colorScheme.error).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_note!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _busy ? null : _send,
                        icon: const Icon(Icons.send_rounded, size: 19),
                        label: Text(_busy ? '…' : 'ثبت تیکت'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
