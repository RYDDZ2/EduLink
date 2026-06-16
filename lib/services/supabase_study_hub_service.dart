import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStudyHubService {
  SupabaseStudyHubService._();

  static const _bucket = 'study-hub-attachments';

  static SupabaseClient get _anon => Supabase.instance.client;

  static SupabaseClient _makeAdmin() {
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

  static Future<void> _ensureBucket(SupabaseClient client) async {
    try {
      await client.storage.getBucket(_bucket);
    } catch (_) {
      await client.storage.createBucket(
        _bucket,
        const BucketOptions(public: true),
      );
    }
  }

  static Future<String> uploadAttachment({
    required String hubId,
    required String userId,
    required String kind,
    required String filePath,
    required String fileExt,
    String? mime,
  }) async {
    final admin = _makeAdmin();
    try {
      await _ensureBucket(admin);

      final safeExt =
          fileExt.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final ext = safeExt.isEmpty ? 'bin' : safeExt;
      final ts = DateTime.now().toUtc().microsecondsSinceEpoch;
      final path = 'study-hub/$hubId/$userId/${ts}_$kind.$ext';

      final bytes = await File(filePath).readAsBytes();
      await admin.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: false, contentType: mime),
          );

      return _anon.storage.from(_bucket).getPublicUrl(path);
    } finally {
      admin.dispose();
    }
  }
}
