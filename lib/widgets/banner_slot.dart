import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'banner_html_stub.dart' if (dart.library.html) 'banner_html_web.dart';


/// بنر پایین تقویم، همان خروجی banner.php سایت.
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key, required this.page});
  final String page;

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  String? _html;
  String? _image;
  String? _title;
  String? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BannerSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse('https://forexfactoryiran.ir/api/public/banner.php?page=${widget.page}'));
      if (res.statusCode != 200) return;
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is! Map || data['active'] != true) return;
      final code = (data['code'] ?? '').toString();
      if (code.isEmpty || !mounted) return;
      final img = RegExp('src="([^"]+)"').firstMatch(code)?.group(1);
      final title = RegExp('bnr-title"[^>]*>([^<]+)').firstMatch(code)?.group(1);
      final sub = RegExp('bnr-subtitle"[^>]*>([^<]+)').firstMatch(code)?.group(1);
      setState(() {
        _html = code;
        _image = img;
        _title = title;
        _sub = sub;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_html == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 970),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _frame(),
          ),
        ),
      ),
    );
  }

  Widget _frame() {
    final web = bannerHtml(_html!, 90);
    if (web is! BannerHtmlMissing) return SizedBox(height: 90, child: web);
    return Container(
      height: 90,
      color: const Color(0xFF1B2333),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          if (_image != null) Image.network(_image!, height: 50, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                if (_sub != null) Text(_sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
