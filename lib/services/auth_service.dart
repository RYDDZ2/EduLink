import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static const Duration _profileRetryDelay = Duration(milliseconds: 350);
  static const int _profileMaxAttempts = 6;

  static Stream<User?> get authStateChanges => auth.authStateChanges();

  static Future<AppUser?> currentProfile() async {
    final user = auth.currentUser;
    if (user == null) return null;

    for (var attempt = 1; attempt <= _profileMaxAttempts; attempt++) {
      try {
        final docRef = firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();
        final data = doc.data();

        if (doc.exists && data != null) {
          return AppUser.fromMap(user.uid, data);
        }

        debugPrint(
          '[AuthService] Profile doc not found for uid=${user.uid} attempt=$attempt/$_profileMaxAttempts',
        );

        if (attempt == _profileMaxAttempts) {
          final fallbackProfile = _fallbackProfileFromAuth(user);
          await docRef.set({
            ...fallbackProfile.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          return fallbackProfile;
        }
      } on FirebaseException catch (e) {
        debugPrint(
          '[AuthService] Failed to read profile uid=${user.uid} attempt=$attempt/$_profileMaxAttempts code=${e.code} message=${e.message}',
        );
        if (!_shouldRetryProfileRead(e) || attempt == _profileMaxAttempts) {
          return _fallbackProfileFromAuth(user);
        }
      } catch (e) {
        debugPrint(
          '[AuthService] Unknown error reading profile uid=${user.uid} attempt=$attempt/$_profileMaxAttempts: $e',
        );
        if (attempt == _profileMaxAttempts) {
          return _fallbackProfileFromAuth(user);
        }
      }

      if (attempt < _profileMaxAttempts) {
        await Future<void>.delayed(_profileRetryDelay);
      }
    }

    return _fallbackProfileFromAuth(user);
  }

  static bool _shouldRetryProfileRead(FirebaseException e) {
    return e.code == 'permission-denied' ||
        e.code == 'unavailable' ||
        e.code == 'aborted';
  }

  static AppUser _fallbackProfileFromAuth(User user) {
    final displayName = user.displayName?.trim();
    final email = user.email?.trim() ?? '';

    return AppUser(
      id: user.uid,
      name: displayName == null || displayName.isEmpty
          ? 'EduLink User'
          : displayName,
      email: email,
      role: UserRole.student,
      knowledgePoints: 320,
    );
  }

  static Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name.trim());

    final profile = AppUser(
      id: user.uid,
      name: name.trim(),
      email: email.trim(),
      role: role,
      knowledgePoints: role == UserRole.student ? 320 : 120,
    );

    await firestore.collection('users').doc(user.uid).set({
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return profile;
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> logout() => auth.signOut();
}
