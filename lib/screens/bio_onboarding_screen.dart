import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/bio_fields_form.dart';

/// Halaman wajib diisi setelah register (atau saat login pertama kali
/// setelah fitur ini ditambahkan) agar profil "jabatan" pengguna lengkap
/// sebelum masuk ke marketplace.
class BioOnboardingScreen extends StatefulWidget {
  final AppUser currentUser;
  final VoidCallback onCompleted;

  const BioOnboardingScreen({
    super.key,
    required this.currentUser,
    required this.onCompleted,
  });

  @override
  State<BioOnboardingScreen> createState() => _BioOnboardingScreenState();
}

class _BioOnboardingScreenState extends State<BioOnboardingScreen> {
  final _bioFormKey = GlobalKey<BioFieldsFormState>();
  bool _isSaving = false;

  Future<void> _submit() async {
    if (!_bioFormKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final studentBio = _bioFormKey.currentState!.studentBio;
      final tutorBio = _bioFormKey.currentState!.tutorBio;

      await AuthService.firestore
          .collection('users')
          .doc(widget.currentUser.id)
          .set(
        {
          if (studentBio != null) 'studentBio': studentBio.toMap(),
          if (tutorBio != null) 'tutorBio': tutorBio.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      widget.onCompleted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.currentUser.role == UserRole.student;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Lengkapi Profil Kamu',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  isStudent
                      ? 'Ceritakan jenjang pendidikanmu agar tutor lebih mengenalmu di EduLink.'
                      : 'Ceritakan profesimu agar siswa lebih mengenalmu di EduLink.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: BioFieldsForm(
                    key: _bioFormKey,
                    role: widget.currentUser.role,
                    initialStudentBio: widget.currentUser.studentBio,
                    initialTutorBio: widget.currentUser.tutorBio,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan & Lanjutkan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
