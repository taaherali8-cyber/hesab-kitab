import 'package:flutter/material.dart';
import 'data.dart';
import 'jalali.dart';

const dialogBg = Color(0xFF161B28);

ShapeBorder dialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(24),
  side: BorderSide(color: Colors.white.withOpacity(.15)),
);

Future<bool> confirmDelete(BuildContext context, String text) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: dialogBg,
      shape: dialogShape,
      title: const Text('حذف'),
      content: Text(text),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  return ok == true;
}

/// افزودن / ویرایش طرف حساب
Future<void> showPersonDialog(BuildContext context, {Person? existing}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final note = TextEditingController(text: existing?.note ?? '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: dialogBg,
        shape: dialogShape,
        title: Text(existing == null ? 'افزودن طرف حساب' : 'ویرایش طرف حساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: existing == null,
              onChanged: (_) => setS(() {}),
              decoration: const InputDecoration(labelText: 'نام', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration:
                  const InputDecoration(labelText: 'یادداشت (اختیاری)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(
            onPressed: name.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    ),
  );

  if (ok == true) {
    if (existing != null) {
      existing.name = name.text.trim();
      existing.note = note.text.trim();
      await Store.I.save();
    } else {
      Store.I.addPerson(name.text.trim(), note.text.trim());
    }
  }
}

/// افزودن / ویرایش تراکنش
Future<void> showTxnDialog(BuildContext context,
    {required String personId, Txn? existing}) async {
  bool given = existing?.given ?? true;
  final amountCtrl =
      TextEditingController(text: existing == null ? '' : existing.amount.toString());
  final noteCtrl = TextEditingController(text: existing?.note ?? '');
  DateTime date = existing?.date ?? DateTime.now();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: dialogBg,
        shape: dialogShape,
        title: Text(existing == null ? 'ثبت تراکنش' : 'ویرایش تراکنش'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('دادم'), icon: Icon(Icons.north_east)),
                ButtonSegment(value: false, label: Text('گرفتم'), icon: Icon(Icons.south_west)),
              ],
              selected: {given},
              onSelectionChanged: (s) => setS(() => given = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                final newText = n == null ? '' : money(n);
                amountCtrl.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: newText.length),
                );
              },
              decoration: const InputDecoration(
                labelText: 'مبلغ',
                suffixText: 'تومان',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'توضیح (اختیاری)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(faDate(date)),
              onPressed: () async {
                final d = await showJalaliPicker(ctx, initial: date);
                if (d != null) setS(() => date = d);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(
            onPressed: (int.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) <= 0
                ? null
                : () => Navigator.pop(ctx, true),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    ),
  );

  if (ok == true) {
    final amount = int.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount <= 0) return;
    if (existing != null) {
      existing
        ..amount = amount
        ..given = given
        ..note = noteCtrl.text
        ..date = date;
      await Store.I.save();
    } else {
      Store.I.addTxn(Txn(
        id: Store.I.newId(),
        personId: personId,
        amount: amount,
        given: given,
        note: noteCtrl.text,
        date: date,
      ));
    }
  }
}