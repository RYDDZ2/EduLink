import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/quiz_model.dart';

class OpenRouterConfig {
  OpenRouterConfig._();

  static const String _baseUrlDefine = String.fromEnvironment(
    'OPENROUTER_BASE_URL',
    defaultValue: 'https://openrouter.ai/api/v1',
  );

  static const String _apiKeyDefine = String.fromEnvironment(
    'OPENROUTER_API_KEY',
  );

  static const String _modelDefine = String.fromEnvironment(
    'OPENROUTER_MODEL',
    defaultValue: '~openai/gpt-latest',
  );

  static String get baseUrl {
    return _envValue('OPENROUTER_BASE_URL', fallback: _baseUrlDefine);
  }

  static String get apiKey {
    return _envValue('OPENROUTER_API_KEY', fallback: _apiKeyDefine);
  }

  static String get model {
    return _envValue('OPENROUTER_MODEL', fallback: _modelDefine);
  }

  static bool get isConfigured => apiKey.trim().isNotEmpty;

  static String _envValue(String key, {required String fallback}) {
    if (!dotenv.isInitialized) return fallback;
    final value = dotenv.maybeGet(key)?.trim();
    if (value == null || value.isEmpty) return fallback;
    return value;
  }
}

class OpenRouterQuizException implements Exception {
  final String message;

  const OpenRouterQuizException(this.message);

  @override
  String toString() => message;
}

class OpenRouterQuizService {
  OpenRouterQuizService._();

  static Future<List<QuizQuestion>> generateQuestions({
    required String title,
    required String topic,
    required QuizDifficulty difficulty,
    required String materialText,
    required int questionCount,
  }) async {
    if (!OpenRouterConfig.isConfigured) {
      throw const OpenRouterQuizException(
        'OPENROUTER_API_KEY belum diatur. Isi file .env atau jalankan app dengan --dart-define=OPENROUTER_API_KEY=...',
      );
    }

    final response = await http.post(
      _chatCompletionsUri(),
      headers: {
        'Authorization': 'Bearer ${OpenRouterConfig.apiKey}',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://edulink.local',
        'X-OpenRouter-Title': 'EduLink',
      },
      body: jsonEncode({
        'model': OpenRouterConfig.model,
        'temperature': 0.4,
        'stream': false,
        'max_tokens': 4000,
        'messages': [
          {
            'role': 'system',
            'content': _systemPrompt,
          },
          {
            'role': 'user',
            'content': _userPrompt(
              title: title,
              topic: topic,
              difficulty: difficulty,
              materialText: materialText,
              questionCount: questionCount,
            ),
          },
        ],
        'response_format': {
          'type': 'json_schema',
          'json_schema': {
            'name': 'generated_quiz',
            'strict': true,
            'schema': _quizSchema(questionCount),
          },
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenRouterQuizException(
        'OpenRouter gagal (${response.statusCode}). Coba lagi sebentar.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const OpenRouterQuizException('Respons OpenRouter tidak valid.');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const OpenRouterQuizException(
          'OpenRouter tidak mengembalikan soal.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map) {
      throw const OpenRouterQuizException(
          'Format pilihan OpenRouter tidak valid.');
    }

    final message = firstChoice['message'];
    if (message is! Map) {
      throw const OpenRouterQuizException(
          'Format pesan OpenRouter tidak valid.');
    }

    final content = message['content'];
    final parsedContent = _parseContent(content);
    return _questionsFromGeneratedJson(parsedContent, questionCount);
  }

  static Uri _chatCompletionsUri() {
    final base =
        OpenRouterConfig.baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/chat/completions');
  }

  static const String _systemPrompt =
      'You generate high-quality educational multiple-choice quizzes. '
      'Return only JSON that matches the provided schema.';

  static String _userPrompt({
    required String title,
    required String topic,
    required QuizDifficulty difficulty,
    required String materialText,
    required int questionCount,
  }) {
    return '''
Create $questionCount multiple-choice quiz questions for EduLink.

Rules:
- Use the same language as the source material. If the material mixes languages, use Indonesian.
- Every question must have exactly 4 answer options.
- Exactly one option must be correct.
- Give an explanation for every option, including wrong options.
- Each explanation must follow the language of the question.
- Do not include markdown fences or extra prose.

Quiz title: $title
Topic: $topic
Difficulty: ${_difficultyLabel(difficulty)}

Source material:
$materialText
''';
  }

  static Map<String, dynamic> _quizSchema(int questionCount) {
    return {
      'type': 'object',
      'properties': {
        'questions': {
          'type': 'array',
          'minItems': questionCount,
          'maxItems': questionCount,
          'items': {
            'type': 'object',
            'properties': {
              'question': {
                'type': 'string',
                'description': 'The quiz question.',
              },
              'options': {
                'type': 'array',
                'minItems': 4,
                'maxItems': 4,
                'items': {
                  'type': 'object',
                  'properties': {
                    'text': {
                      'type': 'string',
                      'description': 'Answer option text.',
                    },
                    'explanation': {
                      'type': 'string',
                      'description':
                          'Explanation for why this option is correct or incorrect.',
                    },
                  },
                  'required': ['text', 'explanation'],
                  'additionalProperties': false,
                },
              },
              'correctIndex': {
                'type': 'integer',
                'minimum': 0,
                'maximum': 3,
                'description': 'Zero-based index of the correct option.',
              },
            },
            'required': ['question', 'options', 'correctIndex'],
            'additionalProperties': false,
          },
        },
      },
      'required': ['questions'],
      'additionalProperties': false,
    };
  }

  static Map<String, dynamic> _parseContent(Object? content) {
    if (content is Map<String, dynamic>) return content;

    if (content is! String || content.trim().isEmpty) {
      throw const OpenRouterQuizException('Konten OpenRouter kosong.');
    }

    final trimmed = content.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final sliced = trimmed.substring(start, end + 1);
        final decoded = jsonDecode(sliced);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    }

    throw const OpenRouterQuizException(
      'OpenRouter mengembalikan JSON yang tidak bisa dibaca.',
    );
  }

  static List<QuizQuestion> _questionsFromGeneratedJson(
    Map<String, dynamic> data,
    int expectedCount,
  ) {
    final rawQuestions = data['questions'];
    if (rawQuestions is! List || rawQuestions.length != expectedCount) {
      throw OpenRouterQuizException(
        'Jumlah soal dari AI tidak sesuai. Minta $expectedCount soal.',
      );
    }

    final questions = <QuizQuestion>[];
    for (var i = 0; i < rawQuestions.length; i++) {
      final rawQuestion = rawQuestions[i];
      if (rawQuestion is! Map) {
        throw const OpenRouterQuizException('Format soal dari AI tidak valid.');
      }

      final questionMap = Map<String, dynamic>.from(rawQuestion);
      final questionText = (questionMap['question'] as String? ?? '').trim();
      final rawOptions = questionMap['options'];
      final correctIndex = _intFromGeneratedValue(questionMap['correctIndex']);

      if (questionText.isEmpty ||
          rawOptions is! List ||
          rawOptions.length != 4) {
        throw const OpenRouterQuizException(
          'Soal AI harus punya pertanyaan dan 4 pilihan.',
        );
      }

      if (correctIndex < 0 || correctIndex > 3) {
        throw const OpenRouterQuizException('Index jawaban benar tidak valid.');
      }

      final options = <QuizAnswerOption>[];
      for (final rawOption in rawOptions) {
        if (rawOption is! Map) {
          throw const OpenRouterQuizException(
              'Format opsi jawaban tidak valid.');
        }
        final optionMap = Map<String, dynamic>.from(rawOption);
        final text = (optionMap['text'] as String? ?? '').trim();
        final explanation = (optionMap['explanation'] as String? ?? '').trim();
        if (text.isEmpty || explanation.isEmpty) {
          throw const OpenRouterQuizException(
            'Setiap opsi harus punya teks dan penjelasan.',
          );
        }
        options.add(QuizAnswerOption(text: text, explanation: explanation));
      }

      questions.add(
        QuizQuestion(
          id: 'q-${i + 1}',
          question: questionText,
          options: options,
          correctIndex: correctIndex,
        ),
      );
    }

    return questions;
  }

  static int _intFromGeneratedValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return -1;
  }
}

String _difficultyLabel(QuizDifficulty difficulty) {
  switch (difficulty) {
    case QuizDifficulty.beginner:
      return 'beginner';
    case QuizDifficulty.intermediate:
      return 'intermediate';
    case QuizDifficulty.advanced:
      return 'advanced';
  }
}
