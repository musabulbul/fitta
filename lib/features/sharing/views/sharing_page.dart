import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sharing_controller.dart';
import '../data/sharing_repository.dart';
import '../models/client_link.dart';
import '../models/share_permission.dart';
import 'client_shell.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/core/widgets/primary_button.dart';

class SharingPage extends StatefulWidget {
  const SharingPage({
    super.key,
    required this.ownerUserId,
    required this.currentUserEmail,
    required this.ownerDisplayName,
    required this.ownerPhotoUrl,
  });

  final String ownerUserId;
  final String currentUserEmail;
  final String ownerDisplayName;
  final String ownerPhotoUrl;

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
    if (Get.isRegistered<SharingController>()) {
      final existing = Get.find<SharingController>();
      if (existing.ownerUserId == widget.ownerUserId &&
          existing.currentUserEmail == widget.currentUserEmail) {
        return existing;
      }
      Get.delete<SharingController>();
    }
    return Get.put(
      SharingController(
        repository: SharingRepository(),
        ownerUserId: widget.ownerUserId,
        currentUserEmail: widget.currentUserEmail,
        ownerDisplayName: widget.ownerDisplayName,
        ownerPhotoUrl: widget.ownerPhotoUrl,
      ),
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<SharingController>()) {
      Get.delete<SharingController>();
    }
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
                  Text('Paylaşılacak Bilgiler', style: theme.textTheme.titleMedium),
                  Obx(
                    () => Column(
                      children: [
                        CheckboxListTile(
                          value: controller.sharePhoto.value,
                          title: const Text('Fotoğraf'),
                          subtitle: const Text('Profil fotoğrafını paylaş'),
                          onChanged: (v) => controller.sharePhoto.value = v ?? true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          value: controller.shareWorkouts.value,
                          title: const Text('Egzersiz Bilgileri'),
                          subtitle: const Text('Antrenman planı ve geçmişi'),
                          onChanged: (v) => controller.shareWorkouts.value = v ?? true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          value: controller.shareWeight.value,
                          title: const Text('Kilo Bilgileri'),
                          subtitle: const Text('Kilo ve yağ oranı kayıtları'),
                          onChanged: (v) => controller.shareWeight.value = v ?? true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          value: controller.shareMeasurements.value,
                          title: const Text('Ölçü Bilgileri'),
                          subtitle: const Text('Vücut ölçü kayıtları'),
                          onChanged: (v) => controller.shareMeasurements.value = v ?? true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
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
    final permissions = _permissionSummary(share);
    final displayName = share.targetDisplayName.isNotEmpty
        ? share.targetDisplayName
        : (share.targetEmail.isNotEmpty ? share.targetEmail : share.targetUserId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FittaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$displayName - ${_roleLabel(share.role)}',
                style: theme.textTheme.titleMedium),
            AppSpacing.vXs,
            if (share.targetEmail.isNotEmpty)
              Text(share.targetEmail, style: theme.textTheme.bodySmall),
            if (share.targetEmail.isEmpty)
              Text('User ID: ${share.targetUserId}', style: theme.textTheme.bodySmall),
            if (permissions.isNotEmpty) ...[
              AppSpacing.vXs,
              Text('Paylaşılanlar: $permissions', style: theme.textTheme.bodySmall),
            ],
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

  String _permissionSummary(SharePermission share) {
    final parts = <String>[];
    if (share.sharePhoto) parts.add('Fotoğraf');
    if (share.shareWorkouts) parts.add('Egzersiz');
    if (share.shareWeight) parts.add('Kilo');
    if (share.shareMeasurements) parts.add('Ölçü');
    return parts.join(' • ');
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client});

  final ClientLink client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = client.ownerDisplayName.isNotEmpty
        ? client.ownerDisplayName
        : (client.ownerEmail.isNotEmpty ? client.ownerEmail : client.ownerUserId);
    final permissions = _permissionSummary(client);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FittaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (client.ownerPhotoUrl.isNotEmpty) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(client.ownerPhotoUrl),
                  ),
                  AppSpacing.hSm,
                ],
                Expanded(
              child: Text(name, style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        AppSpacing.vXs,
        if (client.ownerEmail.isNotEmpty)
          Text(client.ownerEmail, style: theme.textTheme.bodySmall),
        Text('Rol: ${_roleLabel(client.role)}', style: theme.textTheme.bodySmall),
        if (permissions.isNotEmpty) ...[
          AppSpacing.vXs,
              Text('Erişim: $permissions', style: theme.textTheme.bodySmall),
            ],
            AppSpacing.vSm,
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Get.to(() => ClientShell(client: client));
                },
                child: const Text('Danışan Profilini Aç'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _permissionSummary(ClientLink client) {
    final parts = <String>[];
    if (client.sharePhoto) parts.add('Fotoğraf');
    if (client.shareWorkouts) parts.add('Egzersiz');
    if (client.shareWeight) parts.add('Kilo');
    if (client.shareMeasurements) parts.add('Ölçü');
    return parts.join(' • ');
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
