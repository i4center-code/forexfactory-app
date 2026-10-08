import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BrokersScreen extends StatelessWidget {
  const BrokersScreen({super.key});

  static const _items = [
    ['ایکس چیف', '۲۰۱۴', '۱۰\$', 'https://my.xchief.com/registration/?a=64b44478'],
    ['آمارکتس', '۲۰۰۷', '۱۰۰\$', 'https://fa.amarketsworld.com/sign-up/real-persian/?g=DI3DTF'],
    ['اپوفایننس', '۲۰۲۰', '۱۰۰\$', 'https://myaccount.opofinance.com/links/go/4566'],
    ['فیبو گروپ', '۱۹۹۸', '۵۰\$', 'https://fg-persian.com/?ref=IB_Scorpionstrategy'],
    ['لایت فایننس', '۲۰۰۵', '۵۰\$', 'https://www.litefinance.org/fa/promo/codes/?code=INVITE_373126087&uid=373126087'],
    ['IFC مارکتس', '۲۰۰۶', '۱\$', 'https://login.ifcmiran.asia/672048/fa/register'],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('بروکر پیشنهادی ردیف اول است. این معرفی به معنی تأیید سایت نیست.', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        for (var i = 0; i < _items.length; i++)
          Card(
            color: i == 0 ? const Color(0xFFF3FAF2) : null,
            child: ListTile(
              title: Text(_items[i][0], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              subtitle: Text('تأسیس ${_items[i][1]}  ·  حداقل ${_items[i][2]}', style: const TextStyle(fontSize: 12)),
              trailing: i == 0
                  ? const Text('پیشنهادی', style: TextStyle(color: Color(0xFF2E8A29), fontSize: 11, fontWeight: FontWeight.w800))
                  : const Icon(Icons.copy, size: 18),
              onTap: () => Clipboard.setData(ClipboardData(text: _items[i][3])),
            ),
          ),
      ],
    );
  }
}
