import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sharing_controller.dart';
import '../data/sharing_repository.dart';
import '../models/client_link.dart';
import '../models/share_permission.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/core/widgets/primary_button.dart';

class SharingPage extends StatefulWidget {
  const SharingPage({super.key, this.ownerUserId, this.currentUserEmail});

  final String? ownerUserId;
  final String? currentUserEmail;

  @override
  State<SharingPage> createState() => _SharingPageState();
}

class _SharingPageState extends State<SharingPage> {
  late final SharingController controller;
  final emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = _provideController();
    ever<String>(controller.emailInput, (v) {
      if (emailCtrl.text != v) emailCtrl.text = v;
    });
  }

  SharingController _provideController() {
    if (Get.isRegistered<SharingController>()) return Get.find<SharingController>();
    const demoUserId = 'demoUser';
    const demoEmail = 'demo@example.com';
    return Get.put(
      SharingController(
        repository: SharingRepository(),
        ownerUserId: widget.ownerUserId ?? demoUserId,
        currentUserEmail: widget.currentUserEmail ?? demoEmail,
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const FittaAppBar(title: 'Paylaşım & Yetkiler'),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FittaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yeni kişi ile paylaş', style: theme.textTheme.headlineSmall),
                  AppSpacing.vSm,
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı e-postası',
                      hintText: 'ornek@mail.com',
                    ),
                    onChanged: (v) => controller.emailInput.value = v,
                  ),
                  AppSpacing.vSm,
                  Text('Rol', style: theme.textTheme.titleMedium),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'trainer',
                          groupValue: controller.selectedRole.value,
                          title: const Text('Antrenör'),
                          subtitle: const Text('Düzenleyebilir'),
                          onChanged: (v) => controller.selectedRole.value = v ?? 'trainer',
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'viewer',
                          groupValue: controller.selectedRole.value,
                          title: const Text('Görüntüleyici'),
                          subtitle: const Text('Sadece görür'),
                          onChanged: (v) => controller.selectedRole.value = v ?? 'viewer',
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vSm,
                  PrimaryButton(
                    label: controller.isLoading.value ? 'Paylaşılıyor...' : 'Paylaş',
                    onPressed: controller.isLoading.value ? null : controller.addShare,
                  ),
                ],
              ),
            ),
            AppSpacing.vMd,
            _SectionTitle(title: 'Verilerime erişebilen kişiler'),
            AppSpacing.vSm,
            ...controller.sharedWith.map((share) => _ShareTile(
                  share: share,
                  onRemove: () => controller.removeShare(share.targetUserId),
                )),
            if (controller.sharedWith.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Henüz paylaşım yapılmadı.'),
              ),
            AppSpacing.vMd,
            _SectionTitle(title: 'Erişebildiğim kullanıcılar (danışanlarım)'),
            AppSpacing.vSm,
            ...controller.clients.map((client) => _ClientTile(client: client)),
            if (controller.clients.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Henüz danışan eklenmedi.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({required this.share, required this.onRemove});

  final SharePermission share;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FittaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${share.targetUserId} - ${_roleLabel(share.role)}',
                style: theme.textTheme.titleMedium),
            AppSpacing.vXs,
            Text('User ID: ${share.targetUserId}', style: theme.textTheme.bodySmall),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRemove,
                child: const Text('Yetkiyi Kaldır'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'trainer':
        return 'Antrenör';
      case 'viewer':
        return 'Görüntüleyici';
      default:
        return role;
    }
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client});

  final ClientLink client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FittaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kullanıcı: ${client.ownerUserId}', style: theme.textTheme.titleMedium),
            AppSpacing.vXs,
            Text('Rol: ${client.role}', style: theme.textTheme.bodySmall),
            AppSpacing.vSm,
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Get.snackbar('Danışan', 'Profil açma eklenecek',
                      snackPosition: SnackPosition.BOTTOM);
                },
                child: const Text('Danışan Profilini Aç'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
