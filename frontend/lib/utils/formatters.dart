/// ตัวช่วยจัดรูปแบบตัวเลข/วันที่ (ไม่ต้องใช้แพ็กเกจ intl)
class Fmt {
  Fmt._();

  static const _thaiMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  /// 1184 -> "1,184"
  static String number(num value) {
    final s = value.round().abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return (value < 0 ? '-' : '') + buf.toString();
  }

  /// 340 -> "฿340.00"
  static String baht(double value) {
    final whole = number(value.truncate());
    final cents = ((value - value.truncate()).abs() * 100).round().toString().padLeft(2, '0');
    return '฿$whole.$cents';
  }

  /// +34 / −100
  static String pointsDelta(int delta) => delta >= 0 ? '+${number(delta)}' : '−${number(-delta)}';

  /// 29 ต.ค. 2569 · 16:42 (ปี พ.ศ.)
  static String thaiDateTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_thaiMonths[d.month - 1]} ${d.year + 543} · $hh:$mm';
  }

  /// 29 ต.ค.
  static String thaiShortDate(DateTime d) => '${d.day} ${_thaiMonths[d.month - 1]}';
}
