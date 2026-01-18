import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/location_controller.dart';
import '../../auth/auth_controller.dart';
import '../services/audio_service.dart';
import '../services/app_monitoring_service.dart';

class ChildDashboard extends StatelessWidget {
  const ChildDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    final locationController = Get.put(LocationController());
    final authController = Get.find<AuthController>();

    // Initialize Audio Service
    final audioService = Get.put(AudioService());
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      audioService.startListeningForCommands(user.uid);

      // Upload Installed Apps
      AppMonitoringService().uploadInstalledApps();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çocuk Modu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.location_circle_fill, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Obx(() => Text(
              locationController.isTracking.value
                ? 'Takip Aktif'
                : 'Takip Devre Dışı',
              style: Theme.of(context).textTheme.headlineSmall,
            )),
            const SizedBox(height: 20),
            if (FirebaseAuth.instance.currentUser != null)
               SelectableText('Eşleşme Kodu: ${FirebaseAuth.instance.currentUser!.uid}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            Obx(() => ElevatedButton.icon(
              onPressed: locationController.isTracking.value
                ? locationController.stopTracking
                : locationController.startTracking,
              icon: Icon(locationController.isTracking.value
                ? Icons.stop
                : Icons.play_arrow),
              label: Text(locationController.isTracking.value
                ? 'Takibi Durdur'
                : 'Takibi Başlat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: locationController.isTracking.value ? Colors.red : Colors.green,
              ),
            )),
          ],
        ),
      ),
    );
  }
}
