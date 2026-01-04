import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  static const _appleClientId = String.fromEnvironment('APPLE_CLIENT_ID');
  static const _appleRedirectUri = String.fromEnvironment('APPLE_REDIRECT_URI');

  static bool get _requiresAppleWebAuth =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  static bool get appleSignInSupported {
    if (_requiresAppleWebAuth) {
      return _appleClientId.isNotEmpty && _appleRedirectUri.isNotEmpty;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      return _auth.signInWithPopup(googleProvider);
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google girişi iptal edildi');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final appleIdCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: _appleWebAuthOptions(),
    );

    final idToken = appleIdCredential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Apple kimlik dogrulama basarisiz: idToken alinamadi.');
    }

    final oAuthProvider = OAuthProvider('apple.com');
    final credential = oAuthProvider.credential(
      idToken: idToken,
      accessToken: appleIdCredential.authorizationCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();

  WebAuthenticationOptions? _appleWebAuthOptions() {
    if (!_requiresAppleWebAuth) return null;
    if (_appleClientId.isEmpty || _appleRedirectUri.isEmpty) {
      throw StateError(
        'Apple ile giris icin APPLE_CLIENT_ID ve APPLE_REDIRECT_URI '
        'dart-define degerlerini ayarlayin.',
      );
    }
    return WebAuthenticationOptions(
      clientId: _appleClientId,
      redirectUri: Uri.parse(_appleRedirectUri),
    );
  }
}
