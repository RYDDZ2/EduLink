import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseChatAttachmentService {
  SupabaseChatAttachmentService._();

  static SupabaseClient get _anonClient {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw StateError(
        'Missing Supabase env. Pastikan SUPABASE_URL dan SUPABASE_ANON_KEY sudah diisi di .env',
      );
    }

    return Supabase.instance.client;
  }

  static SupabaseClient get _adminClient {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];

    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw StateError(
        'Missing SUPABASE_SERVICE_ROLE_KEY di .env. '
        'Cari di Supabase Dashboard → Project Settings → API → service_role_key.',
      );
    }

    return SupabaseClient(url, key);
  }

  static String get _bucket {
    final b = dotenv.env['SUPABASE_CHAT_ATTACHMENTS_BUCKET'];
    // Pakai bucket lama sesuai code base / preferensi user.
    if (b == null || b.isEmpty) return 'chat-attachments';
    return b;
  }

  static Future<void> _ensureBucketExists(SupabaseClient client) async {
    final bucketName = _bucket;
    try {
      await client.storage.getBucket(bucketName);
    } catch (_) {
      await client.storage.createBucket(
        bucketName,
        const BucketOptions(public: true),
      );
    }
  }

  static Future<String> uploadAttachment({
    required String sessionId,
    required String senderId,
    required String kind, // 'image' | 'doc' | 'file'
    required String fileExt,
    required XFileLike xfile,
    required String originalFileName,
    String? mime,
  }) async {
    final admin = _adminClient;
    try {
      await _ensureBucketExists(admin);

      final safeExt = fileExt.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final ts = DateTime.now().toUtc().microsecondsSinceEpoch;
      final ext = safeExt.isEmpty ? 'bin' : safeExt;

      // path: chat/{sessionId}/{senderId}/{ts}_{kind}.{ext}
      final objectPath = 'chat/$sessionId/$senderId/${ts}_${kind}.$ext';

      final bytes = await File(xfile.path).readAsBytes();

      await admin.storage
          .from(_bucket)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: mime,
            ),
          );

      final publicUrl =
          _anonClient.storage.from(_bucket).getPublicUrl(objectPath);
      return publicUrl;
    } finally {
      admin.dispose();
    }
  }
}

/// Minimal wrapper supaya service ini bisa menerima image_picker/file_picker's XFile
/// tanpa harus dependency type yang sama di signature.
class XFileLike {
  final String path;
  const XFileLike(this.path);
}


