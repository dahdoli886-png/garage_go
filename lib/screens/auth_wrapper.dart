import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'role_selection_screen.dart'; // 1. استدعينا شاشة اختيار الدور

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
            backgroundColor: Color(0xFF243141),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFF39C12)),
            ),
          );
        }

        // مسجّل دخول
        if (snapshot.hasData && snapshot.data != null) {
          return const CustomerMainScreen();
        }

        // مش مسجّل
        // 2. التعديل هون: رح يوديه على شاشة اختيار الدور مباشرة
        return const RoleSelectionScreen();
      },
    );
  }
}
