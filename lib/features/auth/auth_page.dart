import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_controller.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;

  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    try {
      if (_isLogin) {
        await authController.signIn(email, password);
      } else {
        await authController.signUp(email, password);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Giriş başarısız');
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Fitta',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Giriş yap' : 'Kayıt ol',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(CupertinoIcons.mail),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v != null && v.contains('@') ? null : 'Geçerli email girin',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Şifre',
                            prefixIcon: Icon(CupertinoIcons.lock),
                          ),
                          obscureText: true,
                          validator: (v) =>
                              v != null && v.length >= 6 ? null : 'En az 6 karakter girin',
                        ),
                        const SizedBox(height: 20),
                        Obx(
                          () => ElevatedButton.icon(
                            icon: Icon(_isLogin
                                ? CupertinoIcons.arrow_right_to_line
                                : CupertinoIcons.person_badge_plus),
                            label: Text(_isLogin ? 'Giriş yap' : 'Kayıt ol'),
                            onPressed: authController.isLoading.value ? null : _submit,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(_isLogin
                              ? 'Hesabın yok mu? Kayıt ol'
                              : 'Zaten hesabın var mı? Giriş yap'),
                        ),
                        const Divider(height: 32),
                        Obx(
                          () => ElevatedButton.icon(
                            icon: const Icon(CupertinoIcons.search),
                            label: const Text('Google ile devam et'),
                            onPressed: authController.isLoading.value
                                ? null
                                : () async {
                                    try {
                                      await authController.signInWithGoogle();
                                    } catch (e) {
                                      _showError(e.toString());
                                    }
                                  },
                        ),
                      ),
                        const SizedBox(height: 8),
                        FutureBuilder<bool>(
                          future: SignInWithApple.isAvailable(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox.shrink();
                            }
                            if (snapshot.data != true) return const SizedBox.shrink();
                            return Obx(
                              () => ElevatedButton.icon(
                                icon: const Icon(CupertinoIcons.person_crop_circle),
                                label: const Text('Apple ile devam et'),
                                onPressed: authController.isLoading.value
                                    ? null
                                    : () async {
                                        try {
                                          await authController.signInWithApple();
                                        } catch (e) {
                                          _showError(e.toString());
                                        }
                                      },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
