import 'package:flutter/material.dart';
import 'data.dart';
import 'glass.dart';
import 'jalali.dart';
import 'person_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _openPerson(Person p) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => PersonScreen(person: p)));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final people = List<Person>.from(Store.I.people)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const GlassBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: [
                      const Text('دفتر حساب',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.insert_chart_outlined),
                        tooltip: 'گزارش',
                        onPressed: () async {
                          await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ReportScreen()));
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'تنظیمات',
                        onPressed: () async {
                          await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()));
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text('مجموع طلب من',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white.withOpacity(.7))),
                              const SizedBox(height: 6),
                              Text(faMoney(Store.I.totalReceivable),
                                  style: const TextStyle(
                                      color: Color(0xFF69F0AE),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text('مجموع بدهی من',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white.withOpacity(.7))),
                              const SizedBox(height: 6),
                              Text(faMoney(Store.I.totalPayable),
                                  style: const TextStyle(
                                      color: Color(0xFFFF8A80),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: people.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: Colors.white.withOpacity(.3)),
                              const SizedBox(height: 12),
                              Text('هنوز طرف حسابی نداری',
                                  style: TextStyle(color: Colors.white.withOpacity(.6))),
                              const SizedBox(height: 4),
                              Text('با دکمه پایین صفحه اولین طرف حساب را اضافه کن',
                                  style:
                                      TextStyle(fontSize: 12, color: Colors.white.withOpacity(.4))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                          itemCount: people.length,
                          itemBuilder: (ctx, i) {
                            final p = people[i];
                            final b = Store.I.balance(p.id);
                            final color = b > 0
                                ? const Color(0xFF69F0AE)
                                : b < 0
                                    ? const Color(0xFFFF8A80)
                                    : Colors.white.withOpacity(.5);
                            final label = b > 0
                                ? 'طلب من از او'
                                : b < 0
                                    ? 'بدهی من به او'
                                    : 'تسویه شده';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                onTap: () => _openPerson(p),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.white.withOpacity(.12),
                                      child: Text(
                                        p.name.isNotEmpty ? p.name.characters.first : '?',
                                        style: const TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name,
                                              style: const TextStyle(
                                                  fontSize: 16, fontWeight: FontWeight.bold)),
                                          if (p.note.isNotEmpty)
                                            Text(p.note,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white.withOpacity(.5))),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(faMoney(b.abs()),
                                            style: TextStyle(color: color, fontSize: 14)),
                                        Text(label,
                                            style: TextStyle(
                                                fontSize: 11, color: Colors.white.withOpacity(.5))),
                                      ],
                                    ),
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
          await showPersonDialog(context);
          setState(() {});
        },
        icon: const Icon(Icons.person_add_alt),
        label: const Text('طرف حساب جدید'),
      ),
    );
  }
}