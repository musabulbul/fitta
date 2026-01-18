import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'map_tracking_view.dart';
import '../../auth/auth_controller.dart';
import 'audio_control_view.dart';
import 'installed_apps_view.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final _codeCtrl = TextEditingController();

  Future<void> _pairWithChild() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final childDoc = await FirebaseFirestore.instance.collection('users').doc(code).get();
      if (!childDoc.exists) {
        Get.snackbar('Hata', 'Kullanıcı bulunamadı');
        return;
      }

      final data = childDoc.data();
      if (data?['role'] != 'child') {
        Get.snackbar('Hata', 'Bu kullanıcı bir çocuk hesabı değil');
        return;
      }

      // Link child to parent
      await FirebaseFirestore.instance.collection('users').doc(code).update({
        'parentId': currentUserId,
      });

      Get.snackbar('Başarılı', 'Çocuk hesabı başarıyla eşleşti');
      _codeCtrl.clear();
      Navigator.pop(context); // Close dialog

    } catch (e) {
      Get.snackbar('Hata', 'Eşleşme başarısız: $e');
    }
  }

  void _showPairDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çocuk Ekle'),
        content: TextField(
          controller: _codeCtrl,
          decoration: const InputDecoration(
            labelText: 'Çocuğun Eşleşme Kodu (UID)',
            hintText: 'Çocuğun ekranındaki kodu girin',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(onPressed: _pairWithChild, child: const Text('Ekle')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ebeveyn Kontrol Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showPairDialog,
            tooltip: 'Çocuk Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.signOut(),
          ),
        ],
      ),
      body: currentUserId == null
        ? const Center(child: Text('Oturum açılmadı'))
        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('parentId', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              final children = snapshot.data?.docs ?? [];
              if (children.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Henüz takip edilen çocuk yok.'),
                      Text('Sağ üstteki + butonuna basarak ekleyin.'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: children.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final childData = children[index].data();
                  final childId = children[index].id;
                  final childName = childData['displayName'] ?? 'İsimsiz Çocuk';
                  final lastLoc = childData['currentLocation'];

                  return Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(CupertinoIcons.person_alt_circle, size: 40),
                          title: Text(childName),
                          subtitle: Text(lastLoc != null ? 'Konum bilgisi mevcut' : 'Konum bilgisi yok'),
                          trailing: const Icon(CupertinoIcons.chevron_right),
                          onTap: () {
                            Get.to(() => MapTrackingView(childId: childId));
                          },
                        ),
                        AudioControlView(childId: childId),
                        TextButton.icon(
                          onPressed: () => Get.to(() => InstalledAppsView(childId: childId)),
                          icon: const Icon(Icons.apps),
                          label: const Text('Yüklü Uygulamaları Gör'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}
