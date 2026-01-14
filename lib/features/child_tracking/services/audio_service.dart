import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription? _commandSubscription;

  /// Starts listening for recording commands from the parent.
  void startListeningForCommands(String childId) {
    _commandSubscription = _firestore
        .collection('users')
        .doc(childId)
        .collection('commands')
        .where('status', isEqualTo: 'pending')
        .where('type', isEqualTo: 'record_audio')
        .snapshots()
        .listen((snapshot) async {
      for (final doc in snapshot.docs) {
        // Mark as processing immediately to avoid double processing
        await doc.reference.update({'status': 'processing'});
        await _handleRecordCommand(childId, doc.id);
      }
    });
  }

  void stopListening() {
    _commandSubscription?.cancel();
  }

  Future<void> _handleRecordCommand(String childId, String commandId) async {
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/audio_$commandId.m4a';

        // Start recording
        await _recorder.start(const RecordConfig(), path: path);

        // Record for 10 seconds
        await Future.delayed(const Duration(seconds: 10));

        final String? recordedUrl = await _recorder.stop();

        if (recordedUrl != null) {
          final file = File(recordedUrl);
          if (await file.exists()) {
             // Upload to Storage
             final ref = _storage.ref().child('audio/$childId/$commandId.m4a');
             await ref.putFile(file);
             final downloadUrl = await ref.getDownloadURL();

             // Update command with result
             await _firestore
                 .collection('users')
                 .doc(childId)
                 .collection('commands')
                 .doc(commandId)
                 .update({
               'status': 'completed',
               'audioUrl': downloadUrl,
               'completedAt': FieldValue.serverTimestamp(),
             });

             // Cleanup
             await file.delete();
             return;
          }
        }
      }
      throw Exception('Recording failed or permission denied');
    } catch (e) {
      print('Error recording audio: $e');
      await _firestore
          .collection('users')
          .doc(childId)
          .collection('commands')
          .doc(commandId)
          .update({
        'status': 'failed',
        'error': e.toString(),
      });
    }
  }
}
