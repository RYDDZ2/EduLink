import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_profile_service.dart';
import '../widgets/bio_fields_form.dart';
import '../widgets/common_widgets.dart';

class EditAccountPage extends StatefulWidget {
  final AppUser currentUser;

  const EditAccountPage({super.key, required this.currentUser});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _nameController = TextEditingController();
  final _bioFormKey = GlobalKey<BioFieldsFormState>();
  final _picker = ImagePicker();

  XFile? _pickedImage;
  bool _isSaving = false;
  late String _initialName;

  @override
  void initState() {
    super.initState();
    _initialName = widget.currentUser.name;
    _nameController.text = widget.currentUser.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFrom(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (x == null) return;
    if (!mounted) return;
    setState(() => _pickedImage = x);
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF0C447C)),
              ),
              title: const Text('Galeri',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Pilih dari foto yang sudah ada'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageFrom(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFF085041)),
              ),
              title: const Text('Kamera',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Ambil foto baru'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageFrom(ImageSource.camera);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    if (!_bioFormKey.currentState!.validate()) return;

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      String? newPhotoUrl;
      if (_pickedImage != null) {
        newPhotoUrl = await SupabaseProfileService.uploadProfilePhoto(
          userId: widget.currentUser.id,
          xfile: _pickedImage!,
        );
      }

      final studentBio = _bioFormKey.currentState!.studentBio;
      final tutorBio = _bioFormKey.currentState!.tutorBio;

      await AuthService.firestore
          .collection('users')
          .doc(widget.currentUser.id)
          .set(
        {
          'name': newName,
          if (newPhotoUrl != null) 'profileImageUrl': newPhotoUrl,
          if (studentBio != null) 'studentBio': studentBio.toMap(),
          if (tutorBio != null) 'tutorBio': tutorBio.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      // Pop with true to signal success — ProfileScreen will refresh
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil diperbarui'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: const Text(
          'Tindakan ini akan menghapus akun, profil, dan seluruh data '
          'terkait secara permanen. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isSaving = true);
    try {
      await AuthService.deleteAccount();

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final password = await _askPassword();
        if (password == null || password.isEmpty) {
          if (mounted) setState(() => _isSaving = false);
          return;
        }

        try {
          await AuthService.reauthenticateWithPassword(password);
          await AuthService.deleteAccount();

          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        } catch (e2) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_authErrorMessage(e2))),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_authErrorMessage(e))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _askPassword() {
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Konfirmasi Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Untuk keamanan, masukkan kembali password kamu sebelum '
                'menghapus akun.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(passwordCtrl.text),
              child: const Text('Konfirmasi'),
            ),
          ],
        ),
      ),
    );
  }

  String _authErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Password yang kamu masukkan salah.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
        case 'requires-recent-login':
          return 'Sesi login sudah lama. Silakan login ulang lalu coba lagi.';
        default:
          return e.message ?? 'Gagal menghapus akun (${e.code})';
      }
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.currentUser.profileImageUrl != null &&
        widget.currentUser.profileImageUrl!.isNotEmpty;

    ImageProvider<Object>? imageProvider;
    if (_pickedImage != null) {
      imageProvider = FileImage(File(_pickedImage!.path));
    } else if (hasPhoto) {
      imageProvider = NetworkImage(widget.currentUser.profileImageUrl!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'Pengaturan Akun',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF085041),
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: const Color(0xFFE6F1FB),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Text(
                          widget.currentUser.initials,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0C447C),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _isSaving ? null : _showImagePickerOptions,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.camera_alt_rounded, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _isSaving ? null : _showImagePickerOptions,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Ubah Foto Profil'),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nama Lengkap',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: _initialName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bio Jabatan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.currentUser.role == UserRole.student
                ? 'Tampil di halaman permintaan bantuan agar tutor mengenal jenjangmu.'
                : 'Tampil di profil tutor. Kamu tetap bisa menerima permintaan di luar bidang ini.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
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
              onPressed: _isSaving ? null : _save,
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
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 20),
          const Text(
            'Hapus Akun',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Akun, profil, dan seluruh data terkait akan dihapus permanen dan tidak dapat dikembalikan.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          EduButton(
            label: 'Hapus Akun',
            icon: Icons.delete_forever_rounded,
            isDanger: true,
            onTap: _isSaving ? () {} : _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }
}
