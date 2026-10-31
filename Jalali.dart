import 'package:flutter/material.dart';

const List<String> jMonths = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
];

const List<String> jWeekdays =
    ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];

String toFa(String s) {
  const d = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return s.splitMapJoin(RegExp(r'[0-9]'),
      onMatch: (m) => d[int.parse(m.group(0)!)], onNonMatch: (n) => n);
}

String money(int n) {
  final neg = n < 0;
  final s = n.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('٬');
    b.write(s[i]);
  }
  return (neg ? '−' : '') + b.toString();
}

String faMoney(int n) => '${toFa(money(n))} تومان';

String faDate(DateTime g) {
  final j = gToJ(g);
  return '${toFa(j[2].toString())} ${jMonths[j[1] - 1]} ${toFa(j[0].toString())}';
}

String faWeekday(DateTime g) {
  const map = {
    DateTime.monday: 'دوشنبه',
    DateTime.tuesday: 'سه‌شنبه',
    DateTime.wednesday: 'چهارشنبه',
    DateTime.thursday: 'پنجشنبه',
    DateTime.friday: 'جمعه',
    DateTime.saturday: 'شنبه',
    DateTime.sunday: 'یکشنبه',
  };
  return map[g.weekday]!;
}

bool jLeap(int jy) => const [1, 5, 9, 13, 17, 22, 26, 30].contains(jy % 33);

int jMonthLen(int jy, int jm) =>
    jm <= 6 ? 31 : jm <= 11 ? 30 : (jLeap(jy) ? 30 : 29);

/// میلادی به شمسی
List<int> gToJ(DateTime g) {
  final gy = g.year, gm = g.month, gd = g.day;
  const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  int jy = (gy <= 1600) ? 0 : 979;
  int gy2 = (gy <= 1600) ? gy - 621 : gy - 1600;
  int gy3 = (gm > 2) ? gy2 + 1 : gy2;
  int days = (365 * gy2) +
      ((gy3 + 3) ~/ 4) -
      ((gy3 + 99) ~/ 100) -
      ((gy3 + 399) ~/ 400) -
      80 +
      gd +
      gdm[gm - 1];
  jy += 33 * (days ~/ 12053);
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  int jm = (days < 186) ? 1 + days ~/ 31 : 1 + (days - 186) ~/ 30;
  int jd = 1 + ((days < 186) ? days % 31 : (days - 186) % 30);
  return [jy, jm, jd];
}

/// شمسی به میلادی
DateTime jToG(int jy, int jm, int jd) {
  int gy = (jy <= 979) ? 621 : 1600;
  jy -= (jy <= 979) ? 0 : 979;
  int days = 365 * jy +
      (jy ~/ 33) * 8 +
      ((jy % 33 + 3) ~/ 4) +
      78 +
      jd +
      ((jm < 7) ? (jm - 1) * 31 : (jm - 7) * 30 + 186);
  gy += 400 * (days ~/ 146097);
  days %= 146097;
  if (days > 36524) {
    days--;
    gy += 100 * (days ~/ 36524);
    days %= 36524;
    if (days >= 365) days++;
  }
  gy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    gy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  int gd = days + 1;
  final leap = (gy % 4 == 0 && gy % 100 != 0) || (gy % 400 == 0);
  final sal = [0, 31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  int gm = 1;
  while (gm < 13 && gd > sal[gm]) {
    gd -= sal[gm];
    gm++;
  }
  return DateTime(gy, gm, gd);
}

/// انتخاب‌گر تاریخ شمسی
Future<DateTime?> showJalaliPicker(BuildContext context,
    {required DateTime initial}) {
  final j = gToJ(initial);
  int y = j[0], m = j[1];
  DateTime sel = initial;
  final today = DateTime.now();
  final todayJ = gToJ(today);

  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final firstWd = jToG(y, m, 1).weekday;
        final offset = firstWd == 6 ? 0 : (firstWd == 7 ? 1 : firstWd + 1);
        final days = jMonthLen(y, m);

        Widget dayCell(int d) {
          final g = jToG(y, m, d);
          final isSel = sel.year == g.year && sel.month == g.month && sel.day == g.day;
          final isToday = todayJ[0] == y && todayJ[1] == m && todayJ[2] == d;
          return GestureDetector(
            onTap: () => setS(() => sel = g),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSel
                    ? const Color(0xFF7C4DFF)
                    : isToday
                        ? Colors.white.withOpacity(.08)
                        : Colors.transparent,
                border: isToday && !isSel
                    ? Border.all(color: Colors.white.withOpacity(.4))
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                toFa(d.toString()),
                style: TextStyle(
                  fontSize: 13,
                  color: isSel ? Colors.white : Colors.white.withOpacity(.85),
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF161B28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(.15)),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'ماه قبل',
                onPressed: () => setS(() {
                  m--;
                  if (m < 1) {
                    m = 12;
                    y--;
                  }
                }),
              ),
              Column(
                children: [
                  Text('${jMonths[m - 1]} ${toFa(y.toString())}',
                      style: const TextStyle(fontSize: 16)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                        onPressed: () => setS(() => y++),
                      ),
                      Text(toFa(y.toString()), style: const TextStyle(fontSize: 13)),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        onPressed: () => setS(() => y--),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'ماه بعد',
                onPressed: () => setS(() {
                  m++;
                  if (m > 12) {
                    m = 1;
                    y++;
                  }
                }),
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: jWeekdays
                      .map((w) => Expanded(
                            child: Center(
                              child: Text(w.substring(0, 1),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(.5))),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 42 * ((days + offset) / 7).ceilToDouble(),
                  child: GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1,
                    children: [
                      ...List.generate(offset, (_) => const SizedBox()),
                      ...List.generate(days, (i) => dayCell(i + 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setS(() {
                sel = today;
                final jt = gToJ(today);
                y = jt[0];
                m = jt[1];
              }),
              child: const Text('امروز'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, sel),
              child: const Text('تایید'),
            ),
          ],
        );
      },
    ),
  );
}

/// انتخاب «ماه مشخص» شمسی
Future<List<int>?> showJalaliMonthPicker(BuildContext context,
    {int? initialYear, int? initialMonth}) {
  final nowJ = gToJ(DateTime.now());
  int y = initialYear ?? nowJ[0];
  int m = initialMonth ?? nowJ[1];
  return showDialog<List<int>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: const Color(0xFF161B28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(.15)),
        ),
        title: const Text('انتخاب ماه'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: y,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'سال', border: OutlineInputBorder()),
              items: List.generate(nowJ[0] - 1400 + 1, (i) => 1400 + i)
                  .map((v) => DropdownMenuItem(value: v, child: Text(toFa(v.toString()))))
                  .toList(),
              onChanged: (v) => setS(() => y = v!),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              childAspectRatio: 2.2,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(12, (i) {
                final idx = i + 1;
                final sel = m == idx;
                return Padding(
                  padding: const EdgeInsets.all(3),
                  child: ChoiceChip(
                    label: Center(
                        child: Text(jMonths[i],
                            style: const TextStyle(fontSize: 11))),
                    selected: sel,
                    onSelected: (_) => setS(() => m = idx),
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, [y, m]),
            child: const Text('تایید'),
          ),
        ],
      ),
    ),
  );
}

/// انتخاب «سال مشخص» شمسی
Future<int?> showJalaliYearPicker(BuildContext context, {int? initialYear}) {
  final nowJ = gToJ(DateTime.now());
  int y = initialYear ?? nowJ[0];
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: const Color(0xFF161B28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(.15)),
        ),
        title: const Text('انتخاب سال'),
        content: DropdownButtonFormField<int>(
          value: y,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'سال', border: OutlineInputBorder()),
          items: List.generate(nowJ[0] - 1400 + 1, (i) => 1400 + i)
              .map((v) => DropdownMenuItem(value: v, child: Text(toFa(v.toString()))))
              .toList(),
          onChanged: (v) => setS(() => y = v!),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, y),
            child: const Text('تایید'),
          ),
        ],
      ),
    ),
  );
}