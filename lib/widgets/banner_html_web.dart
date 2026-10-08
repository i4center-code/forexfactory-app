import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class BannerHtmlMissing extends StatelessWidget {
  const BannerHtmlMissing({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget bannerHtml(String htmlText, double height) {
  final viewType = 'ffi-banner-${htmlText.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
    return html.IFrameElement()
      ..srcdoc = '<!DOCTYPE html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:transparent}</style></head><body>$htmlText</body></html>'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('sandbox', 'allow-scripts allow-popups allow-popups-to-escape-sandbox allow-top-navigation-by-user-activation');
  });
  return HtmlElementView(viewType: viewType);
}
