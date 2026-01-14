import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTrackingView extends StatefulWidget {
  final String childId;
  const MapTrackingView({super.key, required this.childId});

  @override
  State<MapTrackingView> createState() => _MapTrackingViewState();
}

class _MapTrackingViewState extends State<MapTrackingView> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};

  // Default to Istanbul
  static const CameraPosition _kDefaultPosition = CameraPosition(
    target: LatLng(41.0082, 28.9784),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konum Takibi')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.childId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          final locationData = data?['currentLocation'] as Map<String, dynamic>?;

          if (locationData == null) {
            return const Center(child: Text('Konum verisi bulunamadı'));
          }

          final lat = locationData['lat'] as double;
          final lng = locationData['lng'] as double;
          final lastUpdated = (locationData['lastUpdated'] as Timestamp?)?.toDate();

          final pos = LatLng(lat, lng);
          _updateMarker(pos, lastUpdated);

          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(target: pos, zoom: 15),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          );
        },
      ),
    );
  }

  Future<void> _updateMarker(LatLng pos, DateTime? time) async {
    final markerId = MarkerId(widget.childId);
    final marker = Marker(
      markerId: markerId,
      position: pos,
      infoWindow: InfoWindow(
        title: 'Çocuk Konumu',
        snippet: time != null ? 'Son güncelleme: ${time.hour}:${time.minute}' : '',
      ),
    );

    setState(() {
      _markers.clear();
      _markers.add(marker);
    });

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(pos));
  }
}
