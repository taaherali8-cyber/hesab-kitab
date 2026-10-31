import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Person {
  String id;
  String name;
  String note;
  Person({required this.id, required this.name, this.note = ''});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'note': note};
  factory Person.fromMap(Map m) =>
      Person(id: m['id'].toString(), name: m['name'] ?? '', note: m['note'] ?? '');
}

class Txn {
  String id;
  String personId;
  int amount;
  bool given; // true = دادم (طلب من از او) | false = گرفتم (بدهی من به او)
  String note;
  DateTime date;

  Txn({
    required this.id,
    required this.personId,
    required this.amount,
    required this.given,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'personId': personId,
        'amount': amount,
        'given': given,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory Txn.fromMap(Map m) => Txn(
        id: m['id'].toString(),
        personId: m['personId'].toString(),
        amount: (m['amount'] ?? 0).toInt(),
        given: m['given'] == true,
        note: m['note'] ?? '',
        date: DateTime.parse(m['date']),
      );
}

class Store {
  Store._();
  static final Store I = Store._();

  List<Person> people = [];
  List<Txn> txns = [];
  bool lockEnabled = false;
  String pin = '';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    try {
      people = ((jsonDecode(p.getString('people') ?? '[]') as List))
          .map((e) => Person.fromMap(e))
          .toList();
      txns = ((jsonDecode(p.getString('txns') ?? '[]') as List))
          .map((e) => Txn.fromMap(e))
          .toList();
    } catch (_) {
      people = [];
      txns = [];
    }
    lockEnabled = p.getBool('lockEnabled') ?? false;
    pin = p.getString('pin') ?? '';
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('people', jsonEncode(people.map((e) => e.toMap()).toList()));
    await p.setString('txns', jsonEncode(txns.map((e) => e.toMap()).toList()));
    await p.setBool('lockEnabled', lockEnabled);
    await p.setString('pin', pin);
  }

  String newId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  // مانده یک طرف‌حساب: مثبت = طلب من از او، منفی = بدهی من به او
  int balance(String personId) => txns
      .where((t) => t.personId == personId)
      .fold(0, (s, t) => s + (t.given ? t.amount : -t.amount));

  int get totalReceivable => people.fold(0, (s, p) {
        final b = balance(p.id);
        return s + (b > 0 ? b : 0);
      });

  int get totalPayable => people.fold(0, (s, p) {
        final b = balance(p.id);
        return s + (b < 0 ? -b : 0);
      });

  List<Txn> txnsOf(String id) => txns
      .where((t) => t.personId == id)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  void addPerson(String name, String note) {
    people.add(Person(id: newId(), name: name, note: note));
    save();
  }

  void removePerson(String id) {
    people.removeWhere((p) => p.id == id);
    txns.removeWhere((t) => t.personId == id);
    save();
  }

  void addTxn(Txn t) {
    txns.add(t);
    save();
  }

  void removeTxn(String id) {
    txns.removeWhere((t) => t.id == id);
    save();
  }

  String exportJson() => jsonEncode({
        'people': people.map((e) => e.toMap()).toList(),
        'txns': txns.map((e) => e.toMap()).toList(),
      });

  Future<void> importJson(String s) async {
    final m = jsonDecode(s);
    people = ((m['people'] ?? []) as List).map((e) => Person.fromMap(e)).toList();
    txns = ((m['txns'] ?? []) as List).map((e) => Txn.fromMap(e)).toList();
    await save();
  }

  Future<void> clearAll() async {
    people = [];
    txns = [];
    await save();
  }
}