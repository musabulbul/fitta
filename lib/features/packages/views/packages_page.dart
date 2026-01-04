import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/features/sharing/data/sharing_repository.dart';
import 'package:fitta/features/exercises/data/exercise_repository.dart';
import '../controllers/package_controller.dart';
import '../data/package_repository.dart';
import 'edit_package_page.dart';
import '../models/workout_package.dart';

class PackagesPage extends StatelessWidget {
  const PackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = _provideController();

    return Scaffold(
      appBar: const FittaAppBar(title: 'Hazır Paketlerim'),
      body: Obx(() {
        if (controller.packages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.cube_box, size: 48, color: Colors.grey),
                AppSpacing.vSm,
                const Text('Henüz paket oluşturmadınız.'),
                AppSpacing.vSm,
                FilledButton.icon(
                  onPressed: () => Get.to(() => const EditPackagePage()),
                  icon: const Icon(CupertinoIcons.add),
                  label: const Text('Yeni Paket Oluştur'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.packages.length,
          itemBuilder: (context, index) {
            final pkg = controller.packages[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FittaCard(
                child: ListTile(
                  title: Text(pkg.name),
                  subtitle: Text(
                    '${pkg.exercises.length} egzersiz${pkg.description != null ? ' • ${pkg.description}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Get.to(() => EditPackagePage(package: pkg)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.paperplane),
                        tooltip: 'Müşteriye Gönder',
                        onPressed: () => _sendPackageToClient(context, pkg),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.trash),
                        onPressed: () => controller.deletePackage(pkg.id),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const EditPackagePage()),
        child: const Icon(CupertinoIcons.add),
      ),
    );
  }

  void _sendPackageToClient(BuildContext context, WorkoutPackage pkg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final sharingRepo = SharingRepository();
        final userId = Get.find<PackageController>().userId;

        return StreamBuilder(
          stream: sharingRepo.watchClients(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final clients = snapshot.data ?? [];
            if (clients.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Henüz ekli bir müşteriniz yok.'),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Hangi müşteriye gönderilsin?', style: Theme.of(context).textTheme.titleMedium),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: clients.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return ListTile(
                        leading: const Icon(CupertinoIcons.person_crop_circle),
                        title: Text(client.ownerUserId), // In real app, fetch user name
                        subtitle: Text(client.role),
                        trailing: const Icon(CupertinoIcons.paperplane_fill, color: Colors.blue),
                        onTap: () {
                          Get.back();
                          _confirmAndSend(context, pkg, client.ownerUserId);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndSend(BuildContext context, WorkoutPackage pkg, String targetUserId) async {
    // select days
    final selectedDays = <String>[];
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Hangi günlere eklensin?'),
              content: Wrap(
                spacing: 8,
                children: ExerciseRepository.weekDayKeys.map((day) {
                  final label = ExerciseRepository.weekDayLabels[day] ?? day.toUpperCase();
                  final isSelected = selectedDays.contains(day);
                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
                FilledButton(
                  onPressed: () {
                    Get.back();
                    if (selectedDays.isNotEmpty) _executeSend(pkg, targetUserId, selectedDays);
                  },
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeSend(WorkoutPackage pkg, String targetUserId, List<String> dayKeys) async {
    final exerciseRepo = ExerciseRepository();
    try {
      await exerciseRepo.savePlanForDays(
        userId: targetUserId,
        dayKeys: dayKeys,
        exercises: pkg.exercises,
        planName: pkg.name,
      );
      Get.snackbar('Başarılı', 'Paket müşteriye gönderildi');
    } catch (e) {
      Get.snackbar('Hata', 'Gönderilemedi: $e');
    }
  }

  PackageController _provideController() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (Get.isRegistered<PackageController>()) {
      final existing = Get.find<PackageController>();
      if (existing.userId == userId) return existing;
      Get.delete<PackageController>();
    }
    return Get.put(PackageController(repository: PackageRepository(), userId: userId));
  }
}
