import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProfileService {
  SupabaseProfileService._();

  /// Client anon (untuk read public files via UI).
  static SupabaseClient get _client {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw StateError(
        'Missing Supabase env. Pastikan SUPABASE_URL dan SUPABASE_ANON_KEY sudah diisi di .env',
      );
    }
    return Supabase.instance.client;
  }

  /// Client admin (service role) untuk upload — bypass RLS.
  /// Wajib ada SUPABASE_SERVICE_ROLE_KEY di .env.
  static SupabaseClient get _adminClient {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw StateError(
        'Missing SUPABASE_SERVICE_ROLE_KEY di .env. '
        'Cari di Supabase Dashboard → Project Settings → API → service_role_key.\n'
        'Tambahkan: SUPABASE_SERVICE_ROLE_KEY=eyJ...',
      );
    }
    return SupabaseClient(
      url,
      key,
    );
  }

  static String get _bucket {
    final b = dotenv.env['SUPABASE_STORAGE_BUCKET'];
    if (b == null || b.isEmpty) return 'profile-images';
    return b;
  }

  /// Pastikan bucket sudah ada, kalau belum buat baru.
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

  /// Upload foto ke Supabase Storage menggunakan **service role key**
  /// agar tidak kena RLS (Row Level Security).
  /// Bucket akan auto-created kalau belum ada.
  /// Return: public URL (string) untuk ditampilkan di UI.
  static Future<String> uploadProfilePhoto({
    required String userId,
    required XFile xfile,
  }) async {
    // Pakai admin client biar bypass RLS policy
    final client = _adminClient;

    // Pastikan bucket ada sebelum upload
    await _ensureBucketExists(client);

    final ext = xfile.path.split('.').last;
    final fileName = 'users/$userId/profile.$ext';

    final bytes = await File(xfile.path).readAsBytes();

    await client.storage
        .from(_bucket)
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    // Public URL tetap pakai anon client
    final publicUrl = _client.storage.from(_bucket).getPublicUrl(fileName);

    // Dispose admin client
    client.dispose();

    return publicUrl;
  }

  /// Helper untuk inisialisasi Supabase (pakai anon key).
  static Future<void> initSupabase() async {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw StateError('SUPABASE_URL / SUPABASE_ANON_KEY kosong di .env');
    }

    await Supabase.initialize(
      url: url,
      publishableKey: key,
    );
  }
}
