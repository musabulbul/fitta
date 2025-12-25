import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrors {
  static String getMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Bu e-posta adresi zaten kullanımda.';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi.';
        case 'operation-not-allowed':
          return 'Bu işlem şu anda yapılamıyor.';
        case 'weak-password':
          return 'Şifre çok zayıf.';
        case 'user-disabled':
          return 'Kullanıcı hesabı devre dışı bırakılmış.';
        case 'user-not-found':
          return 'Kullanıcı bulunamadı.';
        case 'wrong-password':
          return 'Hatalı şifre.';
        case 'invalid-credential':
          return 'Giriş bilgileri hatalı veya süresi dolmuş.';
        case 'account-exists-with-different-credential':
          return 'Bu e-posta ile daha önce farklı bir yöntemle giriş yapılmış.';
        default:
          return 'Bir hata oluştu: ${error.message}';
      }
    }
    return 'Bir hata oluştu: $error';
  }
}
