/// Persian digit / toman helpers for the sales UI.
/// Kept local to lib/sales/ so we don't touch shared utils.
library;

const _en = '0123456789';
const _fa = '۰۱۲۳۴۵۶۷۸۹';

/// Convert ASCII digits in [input] to Persian digits.
String toPersianDigits(String input) {
  final buf = StringBuffer();
  for (final cu in input.codeUnits) {
    final ch = String.fromCharCode(cu);
    final i = _en.indexOf(ch);
    buf.write(i >= 0 ? _fa[i] : ch);
  }
  return buf.toString();
}

/// Format an integer toman amount with thousands separators and Persian digits.
/// Uses U+066C (Arabic thousands separator٬) which is common in Persian UIs.
String formatToman(int amount, {bool withUnit = true}) {
  final negative = amount < 0;
  final abs = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < abs.length; i++) {
    if (i > 0 && (abs.length - i) % 3 == 0) buf.write('٬');
    buf.write(abs[i]);
  }
  var s = toPersianDigits(buf.toString());
  if (negative) s = '−$s';
  return withUnit ? '$s تومان' : s;
}


/// Plan catalog prices (Nemat / QUOTA_NOTES): exact millions → «۶۰ میلیون تومان».
/// Otherwise falls back to [formatToman] with thousand separators.
String formatPlanPrice(int amount, {bool withUnit = true}) {
  final negative = amount < 0;
  final abs = amount.abs();
  if (abs >= 1000000 && abs % 1000000 == 0) {
    final millions = abs ~/ 1000000;
    var s = toPersianDigits('$millions');
    if (negative) s = '−$s';
    return withUnit ? '$s میلیون تومان' : '$s میلیون';
  }
  return formatToman(amount, withUnit: withUnit);
}

/// Short purchase-success copy (QUOTA_NOTES).
String purchaseSuccessMessage({
  required String nameFa,
  required int priceToman,
  required int balanceAfter,
  bool idempotent = false,
}) {
  final price = formatPlanPrice(priceToman);
  if (idempotent) {
    return 'خرید «$nameFa» قبلاً ثبت شده بود؛ مبلغ $price از کیف پول کسر شده است.';
  }
  return 'خرید «$nameFa» انجام شد؛ $price کسر شد. حالا می‌توانید کلید API بسازید. موجودی مانده: ${formatToman(balanceAfter)}.';
}

/// Parse sales timestamps: ISO-8601 with offset, or naive SQL `YYYY-MM-DD HH:MM:SS`
/// (treated as Asia/Tehran, UTC+03:30).
DateTime? parseSalesDate(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty || s.startsWith('0000-00-00')) return null;

  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;

  final m = RegExp(r'^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2}:\d{2})').firstMatch(s);
  if (m != null) {
    return DateTime.tryParse('${m[1]}T${m[2]}+03:30');
  }
  return null;
}

String _s(dynamic v) => v == null ? '' : v.toString();

int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(_s(v)) ?? fallback;
}

int? asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = _s(v);
  if (s.isEmpty || s.toLowerCase() == 'null') return null;
  return int.tryParse(s);
}

List<String> asStringList(dynamic v) {
  if (v is! List) return const [];
  return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
}

bool asBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = _s(v).toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return fallback;
}
