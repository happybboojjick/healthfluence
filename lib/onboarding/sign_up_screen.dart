// lib/onboarding/sign_up_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'allergy_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인 / 회원가입")),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text("Google로 계속"),
          onPressed: () async {
            try {
              final cred = await AuthService().signInWithGoogle();
              if (cred.user != null && context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AllergyScreen()),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('로그인 실패: $e')),
              );
            }
          },
        ),
      ),
    );
  }
}
