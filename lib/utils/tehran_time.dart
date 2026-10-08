/// Asia/Tehran helpers. Iran has used a fixed UTC+03:30 offset (no DST)
/// since 2022, so a constant offset is correct and needs no tz database.
class TehranTime {
  TehranTime._();
  static const Duration offset = Duration(hours: 3, minutes: 30);

  static DateTime toTehran(DateTime dt) => dt.toUtc().add(offset);

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String time(DateTime? dt) {
    if (dt == null) return '--:--';
    final t = toTehran(dt);
    return '${_two(t.hour)}:${_two(t.minute)}';
  }

  static String date(DateTime? dt) {
    if (dt == null) return '';
    final t = toTehran(dt);
    return '${t.year}-${_two(t.month)}-${_two(t.day)}';
  }

  static String dateTime(DateTime? dt) => dt == null ? '' : '${date(dt)} ${time(dt)}';

  static const _weekdaysFa = ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه'];

  static String dayHeader(DateTime dt) {
    final t = toTehran(dt);
    return '${_weekdaysFa[t.weekday - 1]} ${date(dt)}';
  }

  static String dayKey(DateTime? dt) => dt == null ? 'unknown' : date(dt);
}
