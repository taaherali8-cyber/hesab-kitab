import 'package:flutter/material.dart';
import 'data.dart';
import 'glass.dart';
import 'jalali.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? personId;
  DateTime? from;
  DateTime? to;

  List<Txn> get filtered {
    final list = Store.I.txns.where((t) {
      if (personId != null && t.personId != personId) return false;
      if (from != null &&
          t.date.isBefore(DateTime(from!.year, from!.month, from!.day))) {
        return false;
      }
      if (to != null &&
          t.date.isAfter(DateTime(to!.year, to!.month, to!.day, 23, 59, 59))) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void _setRange(String k) {
    final now = DateTime.now();
    final j = gToJ(now);
    setState(() {
      if (k == 'month') {
        from = jToG(j[0], j[1], 1);
        to = now;
      } else if (k == 'lastMonth') {
        int m = j[1] - 1, y = j[0];
        if (m < 1) {
          m = 12;
          y--;
        }
        from = jToG(y, m, 1);
        to = jToG(y, m, jMonthLen(y, m));
      } else if (k == 'year') {
        from = jToG(j[0], 1, 1);
        to = now;
      } else {
        from = null;
        to = null;
      }
    });
  }

  Future<void> _pickMonth() async {
    final r = await showJalaliMonthPicker(context);
    if (r != null) {
      setState(() {
        from = jToG(r[0], r[1], 1);
        to = jToG(r[0], r[1], jMonthLen(r[0], r[1]));
      });
    }
  }

  Future<void> _pickYear() async {
    final y = await showJalaliYearPicker(context);
    if (y != null) {
      setState(() {
        from = jToG(y, 1, 1);
        to = jToG(y, 12, jMonthLen(y, 12));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    final givenTotal = list.fold<int>(0, (s, t) => s + (t.given ? t.amount : 0));
    final tookTotal = list.fold<int>(0, (s, t) => s + (t.given ? 0 : t.amount));
    final net = givenTotal - tookTotal;

    final perPerson = <String, int>{};
    for (final t in list) {
      perPerson[t.personId] = (perPerson[t.personId] ?? 0) + (t.given ? t.amount : -t.amount);
    }

    String pname(String id) {
      for (final p in Store.I.people) {
        if (p.id == id) return p.name;
      }
      return 'نامشخص';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const GlassBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_forward)),
                      const Expanded(
                        child: Text('گزارش',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String?>(
                          value: personId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'طرف حساب',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null, child: Text('همه')),
                            ...Store.I.people.map(
                                (p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name))),
                          ],
                          onChanged: (v) => setState(() => personId = v),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final d = await showJalaliPicker(context,
                                      initial: from ?? DateTime.now());
                                  if (d != null) setState(() => from = d);
                                },
                                child: Text(
                                    'از: ${from == null ? 'ابتدا' : faDate(from!)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final d = await showJalaliPicker(context,
                                      initial: to ?? DateTime.now());
                                  if (d != null) setState(() => to = d);
                                },
                                child: Text('تا: ${to == null ? 'امروز' : faDate(to!)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                                label: const Text('این ماه'),
                                onPressed: () => _setRange('month')),
                            ActionChip(
                                label: const Text('ماه قبل'),
                                onPressed: () => _setRange('lastMonth')),
                            ActionChip(
                                label: const Text('امسال'),
                                onPressed: () => _setRange('year')),
                            ActionChip(
                                label: const Text('انتخاب ماه'),
                                onPressed: _pickMonth),
                            ActionChip(
                                label: const Text('انتخاب سال'),
                                onPressed: _pickYear),
                            ActionChip(
                                label: const Text('همه'),
                                onPressed: () => _setRange('all')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _sum('مجموع دادم', givenTotal, const Color(0xFF69F0AE)),
                        _sep(),
                        _sum('مجموع گرفتم', tookTotal, const Color(0xFFFF8A80)),
                        _sep(),
                        _sum('خالص', net,
                            net >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80)),
                      ],
                    ),
                  ),
                ),
                if (perPerson.isNotEmpty && personId == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('مانده هر نفر در این بازه',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white.withOpacity(.6))),
                          const SizedBox(height: 6),
                          ...perPerson.entries.map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(pname(e.key),
                                        style: const TextStyle(fontSize: 13))),
                                    Text(faMoney(e.value),
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: e.value >= 0
                                                ? const Color(0xFF69F0AE)
                                                : const Color(0xFFFF8A80))),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Text('تراکنشی در این بازه نیست',
                              style: TextStyle(color: Colors.white.withOpacity(.5))))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: list.length,
                          itemBuilder: (ctx, i) {
                            final t = list[i];
                            final color =
                                t.given ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${t.given ? 'دادم به' : 'گرفتم از'} ${pname(t.personId)}',
                                              style: const TextStyle(
                                                  fontSize: 14, fontWeight: FontWeight.bold)),
                                          Text(
                                              '${faWeekday(t.date)} ${faDate(t.date)}'
                                              '${t.note.isNotEmpty ? ' • ${t.note}' : ''}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white.withOpacity(.5))),
                                        ],
                                      ),
                                    ),
                                    Text(
                                        '${t.given ? '+' : '−'}${toFa(money(t.amount))}',
                                        style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text(' تومان',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.white.withOpacity(.5))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sum(String label, int value, Color color) => Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.6))),
          const SizedBox(height: 4),
          Text(faMoney(value),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      );

  Widget _sep() => Container(width: 1, height: 32, color: Colors.white.withOpacity(.15));
}