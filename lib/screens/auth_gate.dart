import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'student_home_screen.dart';
import 'tutor_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!snapshot.hasData) {
          return const AuthScreen();
        }

        return FutureBuilder<AppUser?>(
          future: AuthService.currentProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final user = profileSnapshot.data;
            if (user == null) {
              return const AuthScreen(
                message: 'Profil belum ditemukan. Silakan login ulang.',
              );
            }

            if (user.role == UserRole.tutor) {
              return TutorHomeScreen(currentUser: user);
            }
            return StudentHomeScreen(currentUser: user);
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.black87)),
    );
  }
}
