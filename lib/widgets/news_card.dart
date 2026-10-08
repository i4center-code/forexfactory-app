import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/fa_format.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppInk.line)),
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(toFa(item.title), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.6)),
                  const SizedBox(height: 6),
                  Text(toFa(item.summary), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppInk.muted, height: 1.8)),
                  const SizedBox(height: 8),
                  Text('${faDateTime(item.publishedAt)} · ${item.source}', style: const TextStyle(fontSize: 11, color: AppInk.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(toFa(item.title), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.7)),
            const SizedBox(height: 8),
            Text(faDateTime(item.publishedAt), style: const TextStyle(fontSize: 11.5, color: AppInk.muted)),
            const SizedBox(height: 12),
            Text(toFa(item.summary), style: const TextStyle(fontSize: 13.5, height: 1.9)),
            const SizedBox(height: 16),
            if (item.url.isNotEmpty)
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('کپی لینک خبر'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: Uri.decodeFull(item.url)));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('لینک کپی شد')));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
