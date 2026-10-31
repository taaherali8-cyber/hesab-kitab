import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'data.dart';
import 'glass.dart';
import 'widgets.dart';

class LockScreen extends StatefulWidget {
  final Widget child;
  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _locked = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_auth);
  }

  Future<void> _auth() async {
    if (_busy || !_locked) return;
    _busy = true;
    try {
      final la = LocalAuthentication();
      final ok = await la.authenticate(
        localizedReason: 'برای ورود به دفتر حساب، احراز هویت کنید',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      if (ok && mounted) setState(() => _locked = false);
    } catch (_) {}
    _busy = false;
    if (mounted) setState(() {});
  }

  void _pinUnlock() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: dialogShape,
        title: const Text('ورود با رمز پشتیبان'),
        content: TextField(
          controller: c,
          obscureText: true,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'رمز', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(
            onPressed: () {
              if (c.text == Store.I.pin && Store.I.pin.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => _locked = false);
              } else {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('رمز اشتباه است')));
              }
            },
            child: const Text('ورود'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const GlassBackground(),
          Center(
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fingerprint, size: 80, color: Color(0xFFB39DFF)),
                  const SizedBox(height: 12),
                  const Text('دفتر حساب قفل است',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('برای ورود، احراز هویت کنید',
                      style: TextStyle(color: Colors.white.withOpacity(.6))),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('احراز هویت'),
                    onPressed: _auth,
                  ),
                  if (Store.I.pin.isNotEmpty)
                    TextButton(onPressed: _pinUnlock, child: const Text('ورود با رمز پشتیبان')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}