import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return StreamBuilder(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        // لسا بيحمّل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // مسجّل دخول
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // مش مسجّل
        return const LoginScreen();
      },
    );
  }
}