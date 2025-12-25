import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitta/features/auth/auth_controller.dart';
import 'package:fitta/features/profile/controllers/profile_controller.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/core/widgets/primary_button.dart';
import 'package:fitta/features/sharing/views/sharing_page.dart';
import 'package:fitta/features/admin/views/admin_exercise_panel_page.dart';
import 'package:fitta/features/packages/views/packages_page.dart';
import 'package:fitta/features/auth/auth_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(ProfileController());

    return Scaffold(
      appBar: const FittaAppBar(title: 'Profil'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FittaCard(
            child: Column(
              children: [
                Obx(() {
                  final user = controller.user.value;
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: controller.pickAndUploadImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                              backgroundImage: controller.photoUrl.value.isNotEmpty
                                  ? NetworkImage(controller.photoUrl.value)
                                  : null,
                              child: controller.photoUrl.value.isEmpty
                                  ? const Icon(CupertinoIcons.person_fill, color: Colors.white)
                                  : null,
                            ),
                            if (controller.isLoading.value)
                              const SizedBox(
                                width: 64, height: 64,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                      ),
                      AppSpacing.hMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  controller.userName.value.isNotEmpty ? controller.userName.value : 'Kullanıcı',
                                  style: theme.textTheme.titleMedium,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16),
                                  onPressed: () => _showNameEditDialog(context, controller),
                                )
                              ],
                            ),
                            Text(user?.email ?? '', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(CupertinoIcons.cube_box_fill, color: theme.colorScheme.primary),
                  title: const Text('Hazır Paketlerim'),
                  subtitle: const Text('Antrenman paketleri oluştur ve gönder'),
                  trailing: const Icon(CupertinoIcons.forward),
                  onTap: () => Get.to(() => const PackagesPage()),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark / Light'),
                  subtitle: const Text('Tema tercihi'),
                  value: Get.isDarkMode,
                  onChanged: (_) => controller.toggleTheme(),
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
                  icon: const Icon(CupertinoIcons.square_arrow_right, size: 18),
                  onPressed: () async {
                    final auth = Get.find<AuthController>();
                    await auth.signOut();
                    if (FirebaseAuth.instance.currentUser != null) {
                      await FirebaseAuth.instance.signOut();
                    }
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

  void _showNameEditDialog(BuildContext context, ProfileController controller) {
    final nameCtrl = TextEditingController(text: controller.userName.value);
    Get.defaultDialog(
      title: 'İsim Güncelle',
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(labelText: 'İsim'),
      ),
      textConfirm: 'Kaydet',
      textCancel: 'İptal',
      onConfirm: () => controller.updateName(nameCtrl.text),
    );
  }
}
