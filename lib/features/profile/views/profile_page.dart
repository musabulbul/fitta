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
import 'package:fitta/features/auth/auth_page.dart';
import 'package:fitta/features/auth/account_deletion_service.dart';

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
                Obx(
                  () => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Antrenör Modu'),
                    subtitle: const Text('Danışanları hızlıca yönet'),
                    value: controller.trainerMode.value,
                    onChanged: controller.setTrainerMode,
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(CupertinoIcons.person_2_fill, color: theme.colorScheme.primary),
                  title: const Text('Paylaşım / Yetki'),
                  subtitle: const Text('Personal trainer, viewer rollerini yönet'),
                  trailing: const Icon(CupertinoIcons.forward),
                  onTap: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      Get.snackbar('Hata', 'Önce giriş yapmalısınız',
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    final displayName = controller.userName.value.isNotEmpty
                        ? controller.userName.value
                        : (user.displayName ?? user.email ?? 'Kullanıcı');
                    final photoUrl = controller.photoUrl.value.isNotEmpty
                        ? controller.photoUrl.value
                        : (user.photoURL ?? '');
                    Get.to(
                      () => SharingPage(
                        ownerUserId: user.uid,
                        currentUserEmail: user.email ?? '',
                        ownerDisplayName: displayName,
                        ownerPhotoUrl: photoUrl,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Obx(
                  () => controller.isAdmin.value
                      ? ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.table_view, color: theme.colorScheme.primary),
                          title: const Text('Egzersiz Yönetimi (Excel)'),
                          subtitle: const Text('XLSX ile global egzersizleri yönet'),
                          trailing: const Icon(CupertinoIcons.forward),
                          onTap: () => Get.to(() => const AdminExercisePanelPage()),
                        )
                      : const SizedBox.shrink(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark / Light'),
                  subtitle: const Text('Tema tercihi'),
                  value: Get.isDarkMode,
                  onChanged: (_) => controller.toggleTheme(),
                ),
                AppSpacing.vMd,
                PrimaryButton(
                  label: 'Çıkış',
                  icon: const Icon(CupertinoIcons.square_arrow_right, size: 18),
                  onPressed: () async {
                    final auth = Get.find<AuthController>();
                    Get.deleteAll(force: true);
                    await auth.signOut();
                    Get.put<AuthController>(AuthController(), permanent: true);
                    Get.offAll(() => const AuthPage());
                  },
                ),
                AppSpacing.vSm,
                TextButton.icon(
                  onPressed: () => _showDeleteAccountDialog(context),
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Hesabı Sil'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Hata', 'Önce giriş yapmalısınız',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final needsPassword =
        user.providerData.any((p) => p.providerId == 'password');
    final passwordCtrl = TextEditingController();
    var isDeleting = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Hesabı Sil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bu işlem hesabınızı ve verilerinizi kalıcı olarak siler.',
                  ),
                  if (needsPassword) ...[
                    AppSpacing.vSm,
                    TextField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(labelText: 'Şifre'),
                      obscureText: true,
                    ),
                  ] else ...[
                    AppSpacing.vSm,
                    const Text('Devam etmek için tekrar giriş yapılabilir.'),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isDeleting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setState(() => isDeleting = true);
                          final service = AccountDeletionService();
                          try {
                            await service.reauthenticate(
                              password:
                                  needsPassword ? passwordCtrl.text.trim() : null,
                            );
                            await service.deleteUserData();
                            await service.deleteUserStorage();
                            Get.deleteAll(force: true);
                            try {
                              await service.deleteAuthUser();
                            } catch (e) {
                              Get.put<AuthController>(AuthController(), permanent: true);
                              rethrow;
                            }
                            Get.put<AuthController>(AuthController(), permanent: true);
                            Get.offAll(() => const AuthPage());
                          } catch (e) {
                            setState(() => isDeleting = false);
                            Get.snackbar('Hata', e.toString(),
                                snackPosition: SnackPosition.BOTTOM);
                          }
                        },
                  child: Text(isDeleting ? 'Siliniyor...' : 'Hesabı Sil'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordCtrl.dispose();
  }
}
