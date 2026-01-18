import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_apps/device_apps.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppMonitoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadInstalledApps() async {
    // Only available on Android
    if (!Platform.isAndroid) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get list of apps with icons and package names
      List<Application> apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );

      final List<Map<String, dynamic>> appList = apps.map((app) {
        return {
          'appName': app.appName,
          'packageName': app.packageName,
          'versionName': app.versionName,
          'installedAt': DateTime.fromMillisecondsSinceEpoch(app.installTimeMillis).toIso8601String(),
        };
      }).toList();

      await _firestore.collection('users').doc(user.uid).update({
        'installedApps': appList,
        'appsLastUpdated': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('Error uploading apps: $e');
    }
  }
}
