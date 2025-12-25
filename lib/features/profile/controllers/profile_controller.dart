import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final user = Rxn<User>();
  final userName = ''.obs;
  final photoUrl = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    user.bindStream(_auth.authStateChanges());
    ever(user, _loadUserProfile);
  }

  Future<void> _loadUserProfile(User? u) async {
    if (u == null) {
      userName.value = '';
      photoUrl.value = '';
      return;
    }
    try {
      final doc = await _firestore.collection('users').doc(u.uid).get();
      if (doc.exists) {
        final data = doc.data();
        userName.value = data?['displayName'] ?? u.displayName ?? 'Kullanıcı';
        photoUrl.value = data?['photoUrl'] ?? u.photoURL ?? '';
      } else {
        userName.value = u.displayName ?? 'Kullanıcı';
        photoUrl.value = u.photoURL ?? '';
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> updateName(String newName) async {
    if (newName.trim().isEmpty) return;
    final u = _auth.currentUser;
    if (u == null) return;

    isLoading.value = true;
    try {
      await u.updateDisplayName(newName);
      await _firestore.collection('users').doc(u.uid).set({
        'displayName': newName,
      }, SetOptions(merge: true));

      userName.value = newName;
      Get.back(); // Close dialog
      Get.snackbar('Başarılı', 'İsim güncellendi', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadImage() async {
    final u = _auth.currentUser;
    if (u == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      isLoading.value = true;
      try {
        final ref = _storage.ref().child('users/${u.uid}/profile.jpg');
        await ref.putFile(File(pickedFile.path));
        final url = await ref.getDownloadURL();

        await u.updatePhotoURL(url);
        await _firestore.collection('users').doc(u.uid).set({
          'photoUrl': url,
        }, SetOptions(merge: true));

        photoUrl.value = url;
        Get.snackbar('Başarılı', 'Profil fotoğrafı güncellendi', snackPosition: SnackPosition.BOTTOM);
      } catch (e) {
        Get.snackbar('Hata', 'Fotoğraf yüklenemedi: $e', snackPosition: SnackPosition.BOTTOM);
      } finally {
        isLoading.value = false;
      }
    }
  }

  void toggleTheme() {
    if (Get.isDarkMode) {
      Get.changeThemeMode(ThemeMode.light);
    } else {
      Get.changeThemeMode(ThemeMode.dark);
    }
  }
}
