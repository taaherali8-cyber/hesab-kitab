import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'data.dart';
import 'glass.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _setPin() async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: dialogBg,
          shape: dialogShape,
          title: const Text('رمز پشتیبان'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c1,
                obscureText: true,
                keyboardType: TextInputType.number,
                onChanged: (_) => setS(() {}),
                decoration: const InputDecoration(
                    labelText: 'رمز (حداقل ۴ رقم)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: c2,
                obscureText: true,
                keyboardType: TextInputType.number,
                onChanged: (_) => setS(() {}),
                decoration: const InputDecoration(
                    labelText: 'تکرار رمز', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(
              onPressed: c1.text.length >= 4 && c1.text == c2.text
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      Store.I.pin = c1.text;
      await Store.I.save();
      setState(() {});
    }
  }

  Future<void> _toggleLock(bool v) async {
    if (v) {
      if (Store.I.pin.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('اول یک رمز پشتیبان تنظیم کن، بعد قفل را فعال کن')));
        return;
      }
      try {
        final ok = await LocalAuthentication().authenticate(
          localizedReason: 'برای فعال‌سازی قفل، احراز هویت کنید',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );
        Store.I.lockEnabled = ok;
      } catch (_) {
        Store.I.lockEnabled = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('احراز هویت روی این گوشی در دسترس نیست')));
        }
      }
    } else {
      Store.I.lockEnabled = false;
    }
    await Store.I.save();
    setState(() {});
  }

  void _showBackupDialog() {
    final backupText = Store.I.exportJson();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: dialogShape,
        title: const Text('پشتیبان‌گیری'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('این متن را در جایی امن (مثل یادداشت یا تلگرام سوشال) ذخیره کن:',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(.6))),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(backupText, style: const TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
          FilledButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('کپی متن پشتیبان'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: backupText));
              if (context.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('متن پشتیبان کپی شد ✅')));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        child: Text('تنظیمات',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GlassCard(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('قفل با اثر انگشت'),
                          subtitle: Text('ورود به برنامه با اثر انگشت یا رمز گوشی',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(.5))),
                          value: Store.I.lockEnabled,
                          onChanged: _toggleLock,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        onTap: _setPin,
                        child: Row(
                          children: [
                            const Icon(Icons.password_outlined),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('رمز پشتیبان')),
                            Text(Store.I.pin.isEmpty ? 'تنظیم نشده' : 'تنظیم شده',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Store.I.pin.isEmpty
                                        ? Colors.white.withOpacity(.4)
                                        : const Color(0xFF69F0AE))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        onTap: _showBackupDialog,
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_upload_outlined),
                            SizedBox(width: 12),
                            Expanded(child: Text('پشتیبان‌گیری و کپی')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        onTap: () async {
                          final c = TextEditingController();
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: dialogBg,
                              shape: dialogShape,
                              title: const Text('بازیابی پشتیبان'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: c,
                                    maxLines: 6,
                                    decoration: const InputDecoration(
                                        hintText: 'متن پشتیبان را اینجا بچسبان...',
                                        border: OutlineInputBorder()),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.paste, size: 18),
                                    label: const Text('چسباندن از کلیپ‌بورد'),
                                    onPressed: () async {
                                      final data =
                                          await Clipboard.getData(Clipboard.kTextPlain);
                                      if (data?.text != null) c.text = data!.text!;
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('انصراف')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('بازیابی')),
                              ],
                            ),
                          );
                          if (ok == true && c.text.trim().isNotEmpty) {
                            try {
                              await Store.I.importJson(c.text.trim());
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('بازیابی انجام شد ✅')));
                              }
                              setState(() {});
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('متن پشتیبان نامعتبر است')));
                              }
                            }
                          }
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_download_outlined),
                            SizedBox(width: 12),
                            Expanded(child: Text('بازیابی از پشتیبان')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        onTap: () async {
                          if (await confirmDelete(
                              context, 'همه طرف‌حساب‌ها و تراکنش‌ها برای همیشه حذف شوند؟')) {
                            await Store.I.clearAll();
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.delete_forever_outlined, color: Color(0xFFFF8A80)),
                            SizedBox(width: 12),
                            Expanded(
                                child: Text('پاک کردن همه داده‌ها',
                                    style: TextStyle(color: Color(0xFFFF8A80)))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text('دفتر حساب شخصی • نسخه ۱٫۰٫۰',
                            style:
                                TextStyle(fontSize: 11, color: Colors.white.withOpacity(.35))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}