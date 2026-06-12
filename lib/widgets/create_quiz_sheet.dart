import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/quiz_model.dart';
import '../models/user_model.dart';
import '../services/openrouter_quiz_service.dart';
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
  static const int _maxMaterialChars = 12000;
  static const int _maxFileBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _topicCtrl;
  late final TextEditingController _materialCtrl;
  late final TextEditingController _questionCountCtrl;
  late QuizDifficulty _difficulty;
  late QuizMaterialSourceType _materialSourceType;
  QuizBookingSession? _selectedSession;
  String? _materialFileName;
  bool _materialWasTrimmed = false;
  bool _isPickingFile = false;
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _generationError;
  List<QuizQuestion> _generatedQuestions = const [];

  bool get _isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    final quiz = widget.quiz;
    final initialQuestionCount = _initialQuestionCount(quiz);
    _titleCtrl = TextEditingController(text: quiz?.title ?? '');
    _topicCtrl = TextEditingController(text: quiz?.topic ?? '');
    _materialCtrl = TextEditingController(text: quiz?.materialText ?? '');
    _questionCountCtrl =
        TextEditingController(text: initialQuestionCount.toString());
    _difficulty = quiz?.difficulty ?? QuizDifficulty.beginner;
    _materialSourceType =
        quiz?.materialSourceType ?? QuizMaterialSourceType.text;
    _materialFileName = quiz?.materialFileName;
    _generatedQuestions = List<QuizQuestion>.from(quiz?.questions ?? const []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _materialCtrl.dispose();
    _questionCountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.96,
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
                  _isEditing ? 'Edit Quiz AI' : 'Buat Quiz AI',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Pilih sesi, masukkan materi, generate soal pilihan ganda, lalu assign ke siswa.',
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
                _label('Jumlah soal'),
                const SizedBox(height: 6),
                _questionCountField(),
                const SizedBox(height: 14),
                _label('Tingkat kesulitan'),
                const SizedBox(height: 8),
                _DifficultySelector(
                  selected: _difficulty,
                  onChanged: (value) {
                    setState(() {
                      _difficulty = value;
                      _markGenerationDirty(insideSetState: true);
                    });
                  },
                ),
                const SizedBox(height: 14),
                _label('Sumber materi'),
                const SizedBox(height: 8),
                _materialSourceSelector(),
                const SizedBox(height: 12),
                if (_materialSourceType == QuizMaterialSourceType.text)
                  _field(
                    controller: _materialCtrl,
                    hint: 'Tempel catatan, ringkasan bab, atau materi tutor...',
                    maxLines: 7,
                    validator: _required,
                    onChanged: (_) => _markGenerationDirty(),
                  )
                else
                  _uploadPanel(),
                if (_materialWasTrimmed) ...[
                  const SizedBox(height: 8),
                  const _InlineNotice(
                    icon: Icons.content_cut_rounded,
                    text:
                        'Materi dipotong ke 12.000 karakter agar request AI tetap stabil.',
                  ),
                ],
                const SizedBox(height: 16),
                _generateButton(),
                if (_generationError != null) ...[
                  const SizedBox(height: 8),
                  _InlineNotice(
                    icon: Icons.error_outline_rounded,
                    text: _generationError!,
                    color: const Color(0xFFFFF1F1),
                    iconColor: Colors.red,
                    textColor: Colors.red.shade700,
                  ),
                ],
                const SizedBox(height: 16),
                _GeneratedPreview(questions: _generatedQuestions),
                const SizedBox(height: 20),
                _saveButton(),
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
            text: 'Belum ada booking aktif untuk dibuatkan quiz.',
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

  Widget _questionCountField() {
    return TextFormField(
      controller: _questionCountCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: _questionCountValidator,
      onChanged: (_) => _markGenerationDirty(),
      decoration: _inputDeco('1 sampai 10 soal').copyWith(
        prefixIcon: const Icon(Icons.format_list_numbered_rounded, size: 19),
      ),
    );
  }

  Widget _materialSourceSelector() {
    return Row(
      children: [
        Expanded(
          child: _SourceChoice(
            icon: Icons.notes_rounded,
            label: 'Text',
            isSelected: _materialSourceType == QuizMaterialSourceType.text,
            onTap: () => _setMaterialSource(QuizMaterialSourceType.text),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SourceChoice(
            icon: Icons.upload_file_rounded,
            label: 'Upload',
            isSelected: _materialSourceType == QuizMaterialSourceType.upload,
            onTap: () => _setMaterialSource(QuizMaterialSourceType.upload),
          ),
        ),
      ],
    );
  }

  Widget _uploadPanel() {
    final hasMaterial = _materialCtrl.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_outlined, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _materialFileName ?? 'PDF, TXT, atau MD',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _isPickingFile ? null : _pickMaterialFile,
                icon: _isPickingFile
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(hasMaterial ? 'Ganti' : 'Pilih'),
              ),
            ],
          ),
          if (hasMaterial) ...[
            const SizedBox(height: 10),
            Text(
              _materialCtrl.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Upload file maksimal 5 MB. PDF scan/gambar belum didukung.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ],
      ),
    );
  }

  Widget _generateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGenerating || _isSaving ? null : _generateQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3C3489),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black26,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: _isGenerating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(
          _generatedQuestions.isEmpty ? 'Generate Quiz' : 'Regenerate Quiz',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _saveButton() {
    final canSave =
        !_isSaving && !_isGenerating && _generatedQuestions.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canSave ? _submit : null,
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
                _isEditing ? Icons.check_rounded : Icons.assignment_turned_in),
        label: Text(
          _isEditing ? 'Simpan Quiz' : 'Assign Quiz',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }
    return null;
  }

  String? _questionCountValidator(String? value) {
    final count = int.tryParse(value ?? '');
    if (count == null) return 'Masukkan jumlah soal';
    if (count < 1 || count > 10) return 'Jumlah soal maksimal 10';
    return null;
  }

  Future<void> _pickMaterialFile() async {
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'txt', 'md'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final extension = (file.extension ?? '').toLowerCase();
      final bytes = file.bytes;

      if (bytes == null) {
        _showSnack('File belum bisa dibaca. Coba pilih file lain.');
        return;
      }

      if (file.size > _maxFileBytes) {
        _showSnack('Ukuran file maksimal 5 MB.');
        return;
      }

      if (!const ['pdf', 'txt', 'md'].contains(extension)) {
        _showSnack('Format file belum didukung. Gunakan PDF, TXT, atau MD.');
        return;
      }

      final extractedText = extension == 'pdf'
          ? _extractPdfText(bytes)
          : utf8.decode(bytes, allowMalformed: true);
      final cleanedText = extractedText.trim();

      if (cleanedText.isEmpty) {
        _showSnack('Tidak ada teks yang bisa diekstrak dari file ini.');
        return;
      }

      final trimmedText = _trimMaterial(cleanedText);
      setState(() {
        _materialCtrl.text = trimmedText;
        _materialFileName = file.name;
        _materialWasTrimmed = cleanedText.length > _maxMaterialChars;
        _generationError = null;
        _markGenerationDirty(insideSetState: true);
      });
    } catch (_) {
      _showSnack('File gagal diproses. Coba file lain.');
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<void> _generateQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _selectedSession == null) return;

    final materialText = _materialCtrl.text.trim();
    if (materialText.isEmpty) {
      _showSnack('Masukkan atau upload materi terlebih dulu.');
      return;
    }

    final questionCount = int.parse(_questionCountCtrl.text);

    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      final questions = await OpenRouterQuizService.generateQuestions(
        title: _titleCtrl.text.trim(),
        topic: _topicCtrl.text.trim(),
        difficulty: _difficulty,
        materialText: materialText,
        questionCount: questionCount,
      );
      if (!mounted) return;
      setState(() {
        _generatedQuestions = questions;
        _generationError = null;
      });
      _showSnack('Quiz berhasil digenerate.');
    } on OpenRouterQuizException catch (e) {
      if (!mounted) return;
      setState(() => _generationError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _generationError =
            'Quiz gagal digenerate. Cek koneksi dan coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _selectedSession == null) return;
    if (_generatedQuestions.isEmpty) {
      _showSnack('Generate soal terlebih dulu sebelum assign quiz.');
      return;
    }

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
      questionCount: _generatedQuestions.length,
      materialSourceType: _materialSourceType,
      materialFileName: _materialSourceType == QuizMaterialSourceType.upload
          ? _materialFileName
          : null,
      questions: _generatedQuestions,
      updatedAt: now,
    );

    try {
      await QuizService.saveQuiz(saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Quiz berhasil diperbarui' : 'Quiz berhasil di-assign',
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
          content: Text('Quiz gagal disimpan. Coba lagi sebentar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  void _setMaterialSource(QuizMaterialSourceType sourceType) {
    if (_materialSourceType == sourceType) return;
    setState(() {
      _materialSourceType = sourceType;
      _materialWasTrimmed = _materialCtrl.text.length > _maxMaterialChars;
      _markGenerationDirty(insideSetState: true);
    });
  }

  void _markGenerationDirty({bool insideSetState = false}) {
    if (_generatedQuestions.isEmpty) return;
    if (insideSetState) {
      _generatedQuestions = const [];
      return;
    }
    setState(() => _generatedQuestions = const []);
  }

  String _extractPdfText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }

  String _trimMaterial(String text) {
    if (text.length <= _maxMaterialChars) return text;
    return text.substring(0, _maxMaterialChars);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
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

int _initialQuestionCount(Quiz? quiz) {
  if (quiz == null) return 5;
  if (quiz.questionCount > 0) return quiz.questionCount.clamp(1, 10);
  if (quiz.questions.isNotEmpty) return quiz.questions.length.clamp(1, 10);
  return 5;
}

class _GeneratedPreview extends StatelessWidget {
  final List<QuizQuestion> questions;

  const _GeneratedPreview({required this.questions});

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const _InlineNotice(
        icon: Icons.auto_awesome_outlined,
        text: 'Generate quiz untuk melihat preview soal sebelum assign.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E0FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: Color(0xFF3C3489),
              ),
              const SizedBox(width: 8),
              Text(
                '${questions.length} soal siap diassign',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3C3489),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...questions.asMap().entries.map((entry) {
            final question = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == questions.length - 1 ? 0 : 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key + 1}. ${question.question}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    question.options
                        .asMap()
                        .entries
                        .map((option) =>
                            '${String.fromCharCode(65 + option.key)}. ${option.value.text}')
                        .join('\n'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SourceChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceChoice({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color iconColor;
  final Color textColor;

  const _InlineNotice({
    required this.icon,
    required this.text,
    this.color = const Color(0xFFF4F6F8),
    this.iconColor = Colors.black45,
    this.textColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: textColor, height: 1.35),
            ),
          ),
        ],
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
