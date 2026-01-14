import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InstalledAppsView extends StatelessWidget {
  final String childId;
  const InstalledAppsView({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yüklü Uygulamalar')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(childId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Hata'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data();
          final List<dynamic>? apps = data?['installedApps'];

          if (apps == null || apps.isEmpty) {
            return const Center(child: Text('Uygulama listesi bulunamadı.'));
          }

          return ListView.separated(
            itemCount: apps.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final app = apps[index] as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.android),
                title: Text(app['appName'] ?? 'Unknown'),
                subtitle: Text(app['packageName'] ?? ''),
                trailing: Text(app['versionName'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
