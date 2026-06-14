import 'package:flutter/material.dart';

import '../models/user_model.dart';

/// Form isian "Bio Jabatan" yang dipakai di onboarding setelah register
/// dan di halaman Pengaturan Akun.
///
/// Gunakan [GlobalKey<BioFieldsFormState>] untuk memanggil [validate] dan
/// membaca [studentBio]/[tutorBio] saat tombol simpan ditekan.
class BioFieldsForm extends StatefulWidget {
  final UserRole role;
  final StudentBio? initialStudentBio;
  final TutorBio? initialTutorBio;

  const BioFieldsForm({
    super.key,
    required this.role,
    this.initialStudentBio,
    this.initialTutorBio,
  });

  @override
  State<BioFieldsForm> createState() => BioFieldsFormState();
}

class BioFieldsFormState extends State<BioFieldsForm> {
  final _formKey = GlobalKey<FormState>();
  final _kelasSemesterCtrl = TextEditingController();
  final _jurusanCtrl = TextEditingController();
  final _bidangCtrl = TextEditingController();

  late StudentLevel _studentLevel;
  late TutorType _tutorType;

  @override
  void initState() {
    super.initState();
    final studentBio = widget.initialStudentBio;
    final tutorBio = widget.initialTutorBio;

    _studentLevel = studentBio?.level ?? StudentLevel.mahasiswa;
    _kelasSemesterCtrl.text = (studentBio?.kelasSemester ?? 1).toString();
    _jurusanCtrl.text = studentBio?.jurusan ?? '';

    _tutorType = tutorBio?.type ?? TutorType.guru;
    _bidangCtrl.text = tutorBio?.bidang ?? '';
  }

  @override
  void dispose() {
    _kelasSemesterCtrl.dispose();
    _jurusanCtrl.dispose();
    _bidangCtrl.dispose();
    super.dispose();
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  StudentBio? get studentBio {
    if (widget.role != UserRole.student) return null;
    return StudentBio(
      level: _studentLevel,
      kelasSemester: int.tryParse(_kelasSemesterCtrl.text.trim()) ?? 1,
      jurusan: _studentLevel == StudentLevel.mahasiswa
          ? _jurusanCtrl.text.trim()
          : '',
    );
  }

  TutorBio? get tutorBio {
    if (widget.role != UserRole.tutor) return null;
    return TutorBio(type: _tutorType, bidang: _bidangCtrl.text.trim());
  }

  bool get _isMahasiswa => _studentLevel == StudentLevel.mahasiswa;

  String get _kelasSemesterLabel => _isMahasiswa ? 'Semester' : 'Kelas';

  String get _kelasSemesterHint {
    switch (_studentLevel) {
      case StudentLevel.sd:
        return 'cth: 5';
      case StudentLevel.smp:
        return 'cth: 8';
      case StudentLevel.sma:
        return 'cth: 11';
      case StudentLevel.mahasiswa:
        return 'cth: 3';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.role == UserRole.student
            ? _buildStudentFields()
            : _buildTutorFields(),
      ),
    );
  }

  List<Widget> _buildStudentFields() {
    return [
      _label('Jenjang Pendidikan'),
      const SizedBox(height: 6),
      DropdownButtonFormField<StudentLevel>(
        initialValue: _studentLevel,
        decoration: _inputDeco(),
        items: const [
          DropdownMenuItem(value: StudentLevel.sd, child: Text('Pelajar SD')),
          DropdownMenuItem(
              value: StudentLevel.smp, child: Text('Pelajar SMP')),
          DropdownMenuItem(
              value: StudentLevel.sma, child: Text('Pelajar SMA')),
          DropdownMenuItem(
              value: StudentLevel.mahasiswa, child: Text('Mahasiswa')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _studentLevel = value);
        },
      ),
      const SizedBox(height: 14),
      _label(_kelasSemesterLabel),
      const SizedBox(height: 6),
      TextFormField(
        controller: _kelasSemesterCtrl,
        keyboardType: TextInputType.number,
        decoration: _inputDeco(hint: _kelasSemesterHint),
        validator: (value) {
          final n = int.tryParse((value ?? '').trim());
          if (n == null || n < 1 || n > 14) {
            return '$_kelasSemesterLabel tidak valid (1-14)';
          }
          return null;
        },
      ),
      if (_isMahasiswa) ...[
        const SizedBox(height: 14),
        _label('Jurusan'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _jurusanCtrl,
          decoration:
              _inputDeco(hint: 'cth: Informatika, Teknik Elektro'),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Jurusan tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    ];
  }

  List<Widget> _buildTutorFields() {
    return [
      _label('Jabatan'),
      const SizedBox(height: 6),
      DropdownButtonFormField<TutorType>(
        initialValue: _tutorType,
        decoration: _inputDeco(),
        items: const [
          DropdownMenuItem(value: TutorType.guru, child: Text('Guru')),
          DropdownMenuItem(value: TutorType.dosen, child: Text('Dosen')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _tutorType = value);
        },
      ),
      const SizedBox(height: 14),
      _label('Bidang / Mata Pelajaran'),
      const SizedBox(height: 6),
      TextFormField(
        controller: _bidangCtrl,
        decoration: _inputDeco(hint: 'cth: Fisika, Matematika'),
        validator: (value) {
          if ((value ?? '').trim().isEmpty) {
            return 'Bidang tidak boleh kosong';
          }
          return null;
        },
      ),
      const SizedBox(height: 6),
      Text(
        'Kamu tetap bisa menerima permintaan bantuan di luar bidang ini.',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
    ];
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      );

  InputDecoration _inputDeco({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Colors.black45),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      );
}
