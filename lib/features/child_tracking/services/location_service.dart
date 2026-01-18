import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Requests location permissions.
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  /// Starts listening to location updates and uploads them to Firestore.
  Future<void> startTracking(String userId) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _uploadLocation(userId, position);
    }, onError: (e) {
      print('Location stream error: $e');
    });
  }

  /// Stops tracking.
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Uploads the current location to Firestore.
  Future<void> _uploadLocation(String userId, Position position) async {
    try {
      await _firestore.collection('users').doc(userId).collection('location_history').add({
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'speed': position.speed,
        'heading': position.heading,
      });

      // Also update the latest location on the user document for quick access
      await _firestore.collection('users').doc(userId).update({
        'currentLocation': {
          'lat': position.latitude,
          'lng': position.longitude,
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      print('Error uploading location: $e');
    }
  }
}
