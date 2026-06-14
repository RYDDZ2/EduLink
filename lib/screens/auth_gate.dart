import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'bio_onboarding_screen.dart';
import 'student_home_screen.dart';
import 'tutor_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<AppUser?>? _profileFuture;
  String? _profileUid;

  void _refreshProfile() {
    setState(() {
      _profileFuture = AuthService.currentProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final authUser = snapshot.data;
        if (authUser == null) {
          _profileFuture = null;
          _profileUid = null;
          return const AuthScreen();
        }

        if (_profileUid != authUser.uid) {
          _profileUid = authUser.uid;
          _profileFuture = AuthService.currentProfile();
        }

        return FutureBuilder<AppUser?>(
          future: _profileFuture,
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

            if (!user.hasJabatanBio) {
              return BioOnboardingScreen(
                currentUser: user,
                onCompleted: _refreshProfile,
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
