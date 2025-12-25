import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitta/features/auth/auth_controller.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/core/widgets/primary_button.dart';
import 'package:fitta/features/sharing/views/sharing_page.dart';
import 'package:fitta/features/admin/views/admin_exercise_panel_page.dart';
import 'package:fitta/features/auth/auth_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const FittaAppBar(title: 'Profil'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FittaCard(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                      child: const Icon(CupertinoIcons.person_fill, color: Colors.white),
                    ),
                    AppSpacing.hMd,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Musa Bulbul', style: theme.textTheme.titleMedium),
                        Text('musa@example.com', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
                AppSpacing.vMd,
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(CupertinoIcons.person_2_fill, color: theme.colorScheme.primary),
                  title: const Text('Paylaşım / Yetki'),
                  subtitle: const Text('Personal trainer, viewer rollerini yönet'),
                  trailing: const Icon(CupertinoIcons.forward),
                  onTap: () => Get.to(() => const SharingPage()),
                ),
                const SizedBox(height: 6),
                // Admin kullanıcılar için görünür olmalı; burada örnek olması için gösteriliyor.
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.table_view, color: theme.colorScheme.primary),
                  title: const Text('Egzersiz Yönetimi (Excel)'),
                  subtitle: const Text('XLSX ile global egzersizleri yönet'),
                  trailing: const Icon(CupertinoIcons.forward),
                  onTap: () => Get.to(() => const AdminExercisePanelPage()),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark / Light'),
                  subtitle: const Text('Tema tercihi'),
                  value: true,
                  onChanged: (_) {},
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(CupertinoIcons.lock_shield_fill, color: theme.colorScheme.primary),
                  title: const Text('Güvenlik'),
                  subtitle: const Text('Giriş, yetki ve bağlantılar'),
                  trailing: const Icon(CupertinoIcons.forward),
                  onTap: () {},
                ),
                AppSpacing.vMd,
                PrimaryButton(
                  label: 'Çıkış',
                  icon: Icon(CupertinoIcons.square_arrow_right, size: 18),
                  onPressed: () async {
                    final auth = Get.isRegistered<AuthController>()
                        ? Get.find<AuthController>()
                        : Get.put(AuthController());
                    await auth.signOut();
                    await FirebaseAuth.instance.signOut();
                    Get.offAll(() => const AuthPage());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
