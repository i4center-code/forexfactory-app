import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../utils/fa_format.dart';
import '../widgets/site_header.dart';

/// حذف تگ‌های HTML از متن خبر (news.php متن با برچسب می‌فرستد).
String stripHtml(String s) {
  var t = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  t = t.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n');
  t = t.replaceAll(RegExp(r'<[^>]*>'), '');
  t = t
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&rsquo;', '’')
      .replaceAll('&lsquo;', '‘')
      .replaceAll('&mdash;', '—')
      .replaceAll('&ndash;', '–')
      .replaceAll('&hellip;', '…');
  t = t.replaceAll(RegExp(r'[ \t\u00a0]+'), ' ');
  t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return t.trim();
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>> _items = [];
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
      final res = await http.get(Uri.parse('https://forexfactoryiran.ir/api/public/news.php'));
      if (res.statusCode != 200) throw Exception('status ${res.statusCode}');
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final list = data is Map ? data['news'] : null;
      _items = list is List ? list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    } catch (e) {
      _error = 'خبر خوانده نشد';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('تلاش مجدد')),
          ],
        ),
      );
    }
    if (_items.isEmpty) return const Center(child: Text('خبری موجود نیست'));
    return RefreshIndicator(
      color: p.primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final n = _items[i];
          final title = toFa(stripHtml((n['title'] ?? '').toString()));
          final excerpt = toFa(stripHtml((n['excerpt'] ?? n['content'] ?? n['body'] ?? '').toString()));
          final date = faDateTime(n['date'] ?? n['created_at'] ?? n['published_at']);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppInk.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _NewsDetail(item: n))),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.5)),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(excerpt, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppInk.muted, height: 1.7)),
                    ],
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(date, style: const TextStyle(fontSize: 11, color: AppInk.muted)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NewsDetail extends StatelessWidget {
  const _NewsDetail({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final title = toFa(stripHtml((item['title'] ?? '').toString()));
    final body = toFa(stripHtml((item['content'] ?? item['body'] ?? item['excerpt'] ?? '').toString()));
    final date = faDateTime(item['date'] ?? item['created_at'] ?? item['published_at']);
    return Scaffold(
      body: Column(
        children: [
          SiteHeader(section: 'news', onSection: (_) => Navigator.of(context).maybePop(), showBack: true, backLabel: 'خبر'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.6, color: p.primary)),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(date, style: const TextStyle(fontSize: 12, color: AppInk.muted)),
                ],
                const SizedBox(height: 12),
                Divider(color: AppInk.line, height: 1),
                const SizedBox(height: 14),
                SelectableText(body.isEmpty ? 'متنی موجود نیست.' : body, style: const TextStyle(fontSize: 14, height: 1.9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
