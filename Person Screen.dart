import 'package:flutter/material.dart';
import 'data.dart';
import 'glass.dart';
import 'jalali.dart';
import 'widgets.dart';

class PersonScreen extends StatefulWidget {
  final Person person;
  const PersonScreen({super.key, required this.person});

  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    final txns = Store.I.txnsOf(p.id);
    final givenTotal =
        txns.fold<int>(0, (s, t) => s + (t.given ? t.amount : 0));
    final tookTotal =
        txns.fold<int>(0, (s, t) => s + (t.given ? 0 : t.amount));
    final b = givenTotal - tookTotal;

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
                      Expanded(
                        child: Column(
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            if (p.note.isNotEmpty)
                              Text(p.note,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(.5))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'ویرایش',
                        onPressed: () async {
                          await showPersonDialog(context, existing: p);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFFF8A80)),
                        tooltip: 'حذف',
                        onPressed: () async {
                          if (await confirmDelete(
                              context, '«${p.name}» و همه تراکنش‌هایش حذف شود؟')) {
                            Store.I.removePerson(p.id);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('دادم', givenTotal, const Color(0xFF69F0AE)),
                        _divider(),
                        _stat('گرفتم', tookTotal, const Color(0xFFFF8A80)),
                        _divider(),
                        _stat('مانده', b,
                            b >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: txns.isEmpty
                      ? Center(
                          child: Text('هنوز تراکنشی ثبت نشده',
                              style: TextStyle(color: Colors.white.withOpacity(.5))))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          itemCount: txns.length,
                          itemBuilder: (ctx, i) {
                            final t = txns[i];
                            final color =
                                t.given ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                onTap: () async {
                                  await showTxnDialog(context, personId: p.id, existing: t);
                                  setState(() {});
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: color.withOpacity(.15),
                                      child: Icon(
                                        t.given ? Icons.north_east : Icons.south_west,
                                        size: 18,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t.given ? 'دادم' : 'گرفتم',
                                              style: TextStyle(
                                                  color: color,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                          Text(
                                            '${faDate(t.date)}'
                                            '${t.note.isNotEmpty ? ' • ${t.note}' : ''}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(.5)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      onPressed: () async {
                                        if (await confirmDelete(
                                            context, 'این تراکنش حذف شود؟')) {
                                          Store.I.removeTxn(t.id);
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    Text(faMoney(t.amount),
                                        style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showTxnDialog(context, personId: p.id);
          setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('ثبت تراکنش'),
      ),
    );
  }

  Widget _stat(String label, int value, Color color) => Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(.6))),
          const SizedBox(height: 4),
          Text(faMoney(value),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      );

  Widget _divider() => Container(
      width: 1, height: 32, color: Colors.white.withOpacity(.15));
}