import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'auth_service.dart';

class AuthController extends GetxController {
  AuthController({AuthService? service}) : service = service ?? AuthService(FirebaseAuth.instance);

  final AuthService service;

  final isLoading = false.obs;
  final error = RxnString();

  Stream<User?> get authChanges => service.authStateChanges();
  User? get user => service.currentUser;

  Future<void> signIn(String email, String password) async {
    await _guard(() async {
      final cred = await service.signInWithEmail(email, password);
      await _ensureUserDocument(cred.user);
    });
  }

  Future<void> signUp(String email, String password) async {
    await _guard(() async {
      final cred = await service.signUpWithEmail(email, password);
      await _ensureUserDocument(cred.user);
    });
  }

  Future<void> signInWithGoogle() async {
    await _guard(() async {
      final cred = await service.signInWithGoogle();
      await _ensureUserDocument(cred.user);
    });
  }

  Future<void> signInWithApple() async {
    await _guard(() async {
      final cred = await service.signInWithApple();
      await _ensureUserDocument(cred.user);
    });
  }

  Future<void> signOut() async {
    await service.signOut();
  }

  Future<void> _guard(Future<void> Function() fn) async {
    isLoading.value = true;
    error.value = null;
    try {
      await fn();
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _ensureUserDocument(User? user) async {
    if (user == null) return;
    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection('users').doc(user.uid);
    final snap = await ref.get();
    final data = <String, dynamic>{
      'email': user.email?.toLowerCase(),
      'displayName': user.displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!snap.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['provider'] = user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'password';
    }
    await ref.set(data, SetOptions(merge: true));
  }
}
