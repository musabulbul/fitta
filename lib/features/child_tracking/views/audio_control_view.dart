import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AudioControlView extends StatefulWidget {
  final String childId;
  const AudioControlView({super.key, required this.childId});

  @override
  State<AudioControlView> createState() => _AudioControlViewState();
}

class _AudioControlViewState extends State<AudioControlView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRequesting = false;
  String? _statusMessage;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestRecording() async {
    setState(() {
      _isRequesting = true;
      _statusMessage = 'Kayıt isteği gönderildi...';
    });

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.childId)
          .collection('commands')
          .add({
        'type': 'record_audio',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Listen for completion
      docRef.snapshots().listen((snapshot) {
        if (!snapshot.exists) return;
        final data = snapshot.data()!;
        final status = data['status'];

        if (status == 'completed') {
           final url = data['audioUrl'];
           setState(() {
             _statusMessage = 'Kayıt alındı. Oynatılıyor...';
           });
           _playAudio(url);
        } else if (status == 'failed') {
          setState(() {
            _statusMessage = 'Kayıt başarısız: ${data['error']}';
            _isRequesting = false;
          });
        } else if (status == 'processing') {
          setState(() {
            _statusMessage = 'Kayıt yapılıyor (10sn)...';
          });
        }
      });

    } catch (e) {
      setState(() {
        _isRequesting = false;
        _statusMessage = 'Hata: $e';
      });
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _isRequesting = false;
        _statusMessage = 'Tamamlandı.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Oynatma hatası: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Ortam Sesi Dinle', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(_statusMessage!, textAlign: TextAlign.center),
              ),
            ElevatedButton.icon(
              onPressed: _isRequesting ? null : _requestRecording,
              icon: _isRequesting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.mic),
              label: const Text('Şimdi Dinle'),
            )
          ],
        ),
      ),
    );
  }
}
