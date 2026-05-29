import 'package:flutter/material.dart';

import '../models/quiz_model.dart';
import '../models/user_model.dart';

class CreateQuizSheet extends StatefulWidget {
  final AppUser currentUser;
  final Quiz? quiz;
  final ValueChanged<Quiz> onSaved;

  const CreateQuizSheet({
    super.key,
    required this.currentUser,
    required this.onSaved,
    this.quiz,
  });

  @override
  State<CreateQuizSheet> createState() => _CreateQuizSheetState();
}

class _CreateQuizSheetState extends State<CreateQuizSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _topicCtrl;
  late final TextEditingController _targetStudentCtrl;
  late final TextEditingController _materialCtrl;
  late QuizDifficulty _difficulty;

  bool get _isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    final quiz = widget.quiz;
    _titleCtrl = TextEditingController(text: quiz?.title ?? '');
    _topicCtrl = TextEditingController(text: quiz?.topic ?? '');
    _targetStudentCtrl = TextEditingController(
      text: quiz?.targetStudentName ?? '',
    );
    _materialCtrl = TextEditingController(text: quiz?.materialText ?? '');
    _difficulty = quiz?.difficulty ?? QuizDifficulty.beginner;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _targetStudentCtrl.dispose();
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
                  _isEditing ? 'Edit Quiz Draft' : 'Buat Quiz Draft',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Simpan materi dan detail quiz. Pertanyaan AI akan ditambahkan di minggu berikutnya.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
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
                _label('Siswa target'),
                const SizedBox(height: 6),
                _field(
                  controller: _targetStudentCtrl,
                  hint: 'cth: Sinta Rahayu',
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
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: Icon(
                      _isEditing ? Icons.check_rounded : Icons.add_rounded,
                    ),
                    label: Text(
                      _isEditing ? 'Simpan Perubahan' : 'Buat Draft',
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final saved =
        (widget.quiz ??
                Quiz(
                  id: 'quiz-${DateTime.now().microsecondsSinceEpoch}',
                  tutorId: widget.currentUser.id,
                  title: '',
                  topic: '',
                  targetStudentName: '',
                  difficulty: _difficulty,
                  materialText: '',
                  status: QuizStatus.draft,
                  createdAt: DateTime.now(),
                ))
            .copyWith(
              title: _titleCtrl.text.trim(),
              topic: _topicCtrl.text.trim(),
              targetStudentName: _targetStudentCtrl.text.trim(),
              difficulty: _difficulty,
              materialText: _materialCtrl.text.trim(),
            );

    widget.onSaved(saved);
    Navigator.pop(context);
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
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
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
