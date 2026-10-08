// ابزارهای مشترک: ارقام فارسی، تاریخ شمسی (جلالی)، ساعت تهران.
// بدون وابستگی به پکیج خارجی.

const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

const kMonths = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
];
const kWeekdays = [
  'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه',
];
const kWeekdayShort = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

bool _isDigit(int c) => c >= 48 && c <= 57;

/// ارقام انگلیسی/عربی را فارسی می‌کند. [decimal] اعشار را «٫» و % را «٪» می‌کند.
String toFa(Object? v, {bool decimal = true}) {
  if (v == null) return '';
  final s = v.toString();
  final sb = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    final between = i > 0 && i < s.length - 1 && _isDigit(s.codeUnitAt(i - 1)) && _isDigit(s.codeUnitAt(i + 1));
    if (_isDigit(c)) {
      sb.write(_faDigits[c - 48]);
    } else if (c >= 0x660 && c <= 0x669) {
      sb.write(_faDigits[c - 0x660]);
    } else if (c == 46 && decimal && between) {
      sb.write('٫');
    } else if (c == 44 && decimal && between) {
      sb.write('٬');
    } else if (c == 37 && decimal) {
      sb.write('٪');
    } else {
      sb.write(s[i]);
    }
  }
  return sb.toString();
}

/// تبدیل میلادی به شمسی → [سال، ماه، روز]
List<int> gregorianToJalali(int gy, int gm, int gd) {
  const g = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy2 = gm > 2 ? gy + 1 : gy;
  var days = 355666 + 365 * gy + ((gy2 + 3) ~/ 4) - ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400) + gd + g[gm - 1];
  var jy = -1595 + 33 * (days ~/ 12053);
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  int jm;
  int jd;
  if (days < 186) {
    jm = 1 + days ~/ 31;
    jd = 1 + days % 31;
  } else {
    jm = 7 + (days - 186) ~/ 30;
    jd = 1 + (days - 186) % 30;
  }
  return [jy, jm, jd];
}

/// یک روز شمسی
class JDay {
  const JDay(this.y, this.m, this.d, this.wd);
  final int y, m, d;
  final int wd; // 0 = شنبه ... 6 = جمعه
  String get weekdayName => kWeekdays[wd];
  String get weekdayShort => kWeekdayShort[wd];
  String get monthName => kMonths[m - 1];
  String get dayText => toFa(d);
  String get full => '$weekdayName ${toFa(d)} $monthName';
  String get fullWithYear => '$full ${toFa(y)}';
}

/// کلید روز میلادی (yyyy-MM-dd، به وقت تهران) → روز شمسی
JDay? jdayFromKey(String key) {
  final p = key.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  final j = gregorianToJalali(y, m, d);
  final wd = (DateTime.utc(y, m, d).weekday + 1) % 7;
  return JDay(j[0], j[1], j[2], wd);
}

const _tehranOffset = Duration(hours: 3, minutes: 30);

class _Stamp {
  _Stamp(this.dt, this.hasTime);
  final DateTime dt;
  final bool hasTime;
}

_Stamp? _parse(Object? v) {
  if (v is DateTime) return _Stamp(v.toUtc().add(_tehranOffset), true);
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    if (s.length <= 10) return _Stamp(dt, false);
    final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(s);
    if (hasZone) return _Stamp(dt.toUtc().add(_tehranOffset), true);
    return _Stamp(dt, true); // بدون منطقهٔ زمانی: همان ساعت تهران فرض می‌شود
  }
  return null;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// «۷ مهر ۱۴۰۵»
String faDate(Object? v) {
  final s = _parse(v);
  if (s == null) return v == null ? '' : toFa(v);
  final j = gregorianToJalali(s.dt.year, s.dt.month, s.dt.day);
  return '${toFa(j[2])} ${kMonths[j[1] - 1]} ${toFa(j[0])}';
}

/// «۷ مهر ۱۴۰۵ · ۱۴:۳۱» (ساعت تهران)
String faDateTime(Object? v) {
  final s = _parse(v);
  if (s == null) return v == null ? '' : toFa(v);
  final date = faDate(v);
  if (!s.hasTime) return date;
  return '$date · ${toFa('${_two(s.dt.hour)}:${_two(s.dt.minute)}')}';
}
