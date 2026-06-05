import 'package:flutter/material.dart';

import '../models/quiz_model.dart';
import '../models/user_model.dart';
import '../services/quiz_service.dart';
import 'common_widgets.dart';

class CreateQuizSheet extends StatefulWidget {
  final AppUser currentUser;
  final Quiz? quiz;

  const CreateQuizSheet({
    super.key,
    required this.currentUser,
    this.quiz,
  });

  @override
  State<CreateQuizSheet> createState() => _CreateQuizSheetState();
}

class _CreateQuizSheetState extends State<CreateQuizSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _topicCtrl;
  late final TextEditingController _materialCtrl;
  late QuizDifficulty _difficulty;
  QuizBookingSession? _selectedSession;
  bool _isSaving = false;

  bool get _isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    final quiz = widget.quiz;
    _titleCtrl = TextEditingController(text: quiz?.title ?? '');
    _topicCtrl = TextEditingController(text: quiz?.topic ?? '');
    _materialCtrl = TextEditingController(text: quiz?.materialText ?? '');
    _difficulty = quiz?.difficulty ?? QuizDifficulty.beginner;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _materialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isEditing ? 'Edit Materi Quiz' : 'Buat Materi Quiz',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Pilih sesi tutor, lalu simpan materi teks untuk siswa.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                _label('Sesi siswa'),
                const SizedBox(height: 6),
                _isEditing
                    ? _LockedSessionBox(quiz: widget.quiz!)
                    : _sessionPicker(),
                const SizedBox(height: 14),
                _label('Judul quiz'),
                const SizedBox(height: 6),
                _field(
                  controller: _titleCtrl,
                  hint: 'cth: Kuis Integral Substitusi',
                  validator: _required,
                ),
                const SizedBox(height: 14),
                _label('Topik'),
                const SizedBox(height: 6),
                _field(
                  controller: _topicCtrl,
                  hint: 'cth: Matematika - Kalkulus',
                  validator: _required,
                ),
                const SizedBox(height: 14),
                _label('Tingkat kesulitan'),
                const SizedBox(height: 8),
                _DifficultySelector(
                  selected: _difficulty,
                  onChanged: (value) => setState(() => _difficulty = value),
                ),
                const SizedBox(height: 14),
                _label('Materi belajar'),
                const SizedBox(height: 6),
                _field(
                  controller: _materialCtrl,
                  hint: 'Tempel catatan, ringkasan bab, atau materi tutor...',
                  maxLines: 7,
                  validator: _required,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.black26,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isEditing
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                          ),
                    label: Text(
                      _isEditing ? 'Simpan Perubahan' : 'Assign Materi',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sessionPicker() {
    return StreamBuilder<List<QuizBookingSession>>(
      stream: QuizService.tutorBookedSessions(widget.currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BoxMessage(
            icon: Icons.sync_rounded,
            text: 'Memuat sesi booking...',
          );
        }

        if (snapshot.hasError) {
          return const _BoxMessage(
            icon: Icons.cloud_off_outlined,
            text: 'Sesi booking belum bisa dimuat.',
          );
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return const _BoxMessage(
            icon: Icons.event_busy_rounded,
            text: 'Belum ada booking aktif untuk dibuatkan materi.',
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedSession?.id,
          isExpanded: true,
          validator: (value) =>
              value == null ? 'Pilih sesi siswa terlebih dulu' : null,
          decoration: _inputDeco('Pilih sesi booking'),
          items: sessions.map((session) {
            return DropdownMenuItem(
              value: session.id,
              child: Text(
                '${session.studentName} - ${session.subject}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (id) {
            setState(() {
              _selectedSession =
                  sessions.firstWhere((session) => session.id == id);
            });
          },
        );
      },
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _selectedSession == null) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final existing = widget.quiz;
    final session = _selectedSession;
    final saved = (existing ??
            Quiz(
              id: '',
              bookingId: session!.id,
              tutorSessionId: session.tutorSessionId,
              studentId: session.studentId,
              studentName: session.studentName,
              tutorId: session.tutorId,
              tutorName: session.tutorName,
              title: '',
              topic: '',
              targetStudentName: session.studentName,
              difficulty: _difficulty,
              materialText: '',
              status: QuizStatus.assigned,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
      title: _titleCtrl.text.trim(),
      topic: _topicCtrl.text.trim(),
      targetStudentName: existing?.studentName ?? session?.studentName,
      difficulty: _difficulty,
      materialText: _materialCtrl.text.trim(),
      status: QuizStatus.assigned,
      updatedAt: now,
    );

    try {
      await QuizService.saveQuiz(saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Materi quiz berhasil diperbarui'
                : 'Materi quiz berhasil di-assign',
          ),
          backgroundColor: const Color(0xFF085041),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materi quiz gagal disimpan. Coba lagi sebentar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDeco(hint),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }
}

class _LockedSessionBox extends StatelessWidget {
  final Quiz quiz;

  const _LockedSessionBox({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 17, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${quiz.studentName} - ${quiz.tutorName}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          StatusBadge(status: quizStatusToString(quiz.status)),
        ],
      ),
    );
  }
}

class _BoxMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BoxMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  final QuizDifficulty selected;
  final ValueChanged<QuizDifficulty> onChanged;

  const _DifficultySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: QuizDifficulty.values.map((difficulty) {
        final isSelected = selected == difficulty;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: difficulty == QuizDifficulty.values.last ? 0 : 8,
            ),
            child: InkWell(
              onTap: () => onChanged(difficulty),
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black87 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: isSelected ? Colors.black87 : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  _difficultyLabel(difficulty),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

String _difficultyLabel(QuizDifficulty difficulty) {
  switch (difficulty) {
    case QuizDifficulty.beginner:
      return 'Beginner';
    case QuizDifficulty.intermediate:
      return 'Intermediate';
    case QuizDifficulty.advanced:
      return 'Advanced';
  }
}
