import 'package:flutter/material.dart';
import 'data.dart';
import 'home_screen.dart';
import 'lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.I.load();
  runApp(const HesabApp());
}

class HesabApp extends StatelessWidget {
  const HesabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دفتر حساب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: Store.I.lockEnabled
          ? const LockScreen(child: HomeScreen())
          : const HomeScreen(),
    );
  }
}