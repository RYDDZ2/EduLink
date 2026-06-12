import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRequestImageService {
  SupabaseRequestImageService._();

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
    final b = dotenv.env['SUPABASE_REQUEST_IMAGES_BUCKET'];
    if (b == null || b.isEmpty) return 'request-images';
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

  static Future<String> uploadRequestImage({
    required String userId,
    required XFile xfile,
  }) async {
    final admin = _adminClient;
    try {
      await _ensureBucketExists(admin);

      final rawExt = xfile.path.split('.').last.toLowerCase();
      final safeExt = rawExt.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final ext = safeExt.isEmpty ? 'jpg' : safeExt;
      final ts = DateTime.now().toUtc().microsecondsSinceEpoch;
      final objectPath = 'requests/$userId/$ts.$ext';

      final bytes = await File(xfile.path).readAsBytes();

      await admin.storage.from(_bucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
            ),
          );

      return _anonClient.storage.from(_bucket).getPublicUrl(objectPath);
    } finally {
      admin.dispose();
    }
  }
}
