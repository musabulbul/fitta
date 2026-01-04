import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AccountDeletionService {
  AccountDeletionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Kullanici bulunamadi.');
    }
    return user;
  }

  Future<void> reauthenticate({String? password}) async {
    final user = _requireUser();
    final providerId = _primaryProviderId(user);
    if (providerId == null) return;

    if (providerId == 'password') {
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw StateError('Eposta bulunamadi.');
      }
      if (password == null || password.trim().isEmpty) {
        throw StateError('Silme islemi icin sifre gerekli.');
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password.trim(),
      );
      await user.reauthenticateWithCredential(credential);
      return;
    }

    if (providerId == 'google.com') {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw StateError('Google girisi iptal edildi.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      return;
    }

    if (providerId == 'apple.com') {
      final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
        ],
      );
      final idToken = appleIdCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Apple kimlik dogrulama basarisiz.');
      }
      final oauthProvider = OAuthProvider('apple.com');
      final credential = oauthProvider.credential(
        idToken: idToken,
        accessToken: appleIdCredential.authorizationCode,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  Future<void> deleteUserData() async {
    final user = _requireUser();
    final userRef = _firestore.collection('users').doc(user.uid);
    final collections = [
      'workoutPlans',
      'planTemplates',
      'workoutSessions',
      'packages',
      'bodyStats',
      'measurements',
      'sharedWith',
      'clients',
      'profile',
    ];

    for (final name in collections) {
      await _deleteCollection(userRef.collection(name));
    }
    await userRef.delete();
  }

  Future<void> deleteUserStorage() async {
    final user = _requireUser();
    final ref = _storage.ref().child('users/${user.uid}/profile.jpg');
    try {
      await ref.delete();
    } catch (_) {
      // Ignore storage cleanup errors.
    }
  }

  Future<void> deleteAuthUser() async {
    final user = _requireUser();
    await user.delete();
  }

  String? _primaryProviderId(User user) {
    final providers = user.providerData.map((p) => p.providerId).toList();
    if (providers.contains('password')) return 'password';
    if (providers.contains('google.com')) return 'google.com';
    if (providers.contains('apple.com')) return 'apple.com';
    if (providers.isNotEmpty) return providers.first;
    return null;
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    const batchSize = 200;
    while (true) {
      final snap = await collection.limit(batchSize).get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
