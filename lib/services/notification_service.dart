import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/user_model.dart';

/// Mengelola local push notification untuk inbox baru dan pesan chat baru.
///
/// Cara kerja:
/// - Notifikasi muncul saat app aktif di foreground maupun background.
/// - Ketika app ditutup sepenuhnya, notifikasi tidak bisa dikirim
///   (untuk itu butuh FCM + Cloud Function — di luar scope proyek ini).
///
/// Panggil [init] sekali di main(), lalu [watch] saat user login,
/// dan [cancel] saat user logout/dispose.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _androidDetails = AndroidNotificationDetails(
    'edulink_marketplace',
    'EduLink Marketplace',
    channelDescription: 'Notifikasi inbox dan pesan sesi tutor EduLink',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static int _idCounter = 0;
  static StreamSubscription<QuerySnapshot>? _inboxSub;
  static StreamSubscription<QuerySnapshot>? _chatSub;

  /// Inisialisasi plugin notifikasi. Panggil sekali di [main].
  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);

    // Minta izin POST_NOTIFICATIONS (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Minta izin notifikasi di iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Tampilkan system notification.
  static Future<void> show({
    required String title,
    required String body,
  }) async {
    await _plugin.show(_idCounter++, title, body, _details);
  }

  /// Mulai memantau Firestore untuk [user]:
  /// - Inbox: offer baru (student) / booking baru (tutor)
  /// - Chat: pesan baru dari user lain di sesi aktif
  ///
  /// Panggil ini saat user berhasil login (di home screen).
  static void watch(AppUser user) {
    cancel(); // batalkan sesi pemantauan sebelumnya
    final db = FirebaseFirestore.instance;
    final startedAt = DateTime.now();

    _watchInbox(user, db, startedAt);
    _watchChat(user, db, startedAt);
  }

  static void _watchInbox(
    AppUser user,
    FirebaseFirestore db,
    DateTime startedAt,
  ) {
    if (user.role == UserRole.student) {
      // Student: notifikasi ketika tutor menawarkan bantuan
      _inboxSub = db
          .collection('helpOffers')
          .where('studentId', isEqualTo: user.id)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snap) {
        for (final change in snap.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final data = change.doc.data() as Map<String, dynamic>;
          final ts = data['createdAt'];
          final createdAt = ts is Timestamp ? ts.toDate() : null;
          // Lewati dokumen lama yang sudah ada sebelum app dibuka
          if (createdAt == null || createdAt.isBefore(startedAt)) continue;
          final tutorName = data['tutorName'] as String? ?? 'Tutor';
          final reqTitle = data['requestTitle'] as String? ?? '';
          show(
            title: 'Penawaran Bantuan Baru',
            body: '$tutorName menawarkan bantuan untuk: $reqTitle',
          );
        }
      });
    } else {
      // Tutor: notifikasi ketika student meminta booking sesi
      _inboxSub = db
          .collection('sessionBookings')
          .where('tutorId', isEqualTo: user.id)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snap) {
        for (final change in snap.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final data = change.doc.data() as Map<String, dynamic>;
          final ts = data['createdAt'];
          final createdAt = ts is Timestamp ? ts.toDate() : null;
          if (createdAt == null || createdAt.isBefore(startedAt)) continue;
          final studentName = data['studentName'] as String? ?? 'Student';
          final subject = data['subject'] as String? ?? '';
          show(
            title: 'Permintaan Booking Baru',
            body: '$studentName ingin booking sesi $subject',
          );
        }
      });
    }
  }

  static void _watchChat(
    AppUser user,
    FirebaseFirestore db,
    DateTime startedAt,
  ) {
    // Pantau perubahan pada dokumen sesi — field lastMessageAt diupdate
    // setiap kali pesan baru dikirim (oleh MarketplaceService._touchSessionLastMessage)
    _chatSub = db
        .collection('tutoringSessions')
        .where('participants', arrayContains: user.id)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        // Hanya peduli pada update sesi yang sudah ada
        if (change.type != DocumentChangeType.modified) continue;
        final data = change.doc.data() as Map<String, dynamic>;
        final lastSenderId = data['lastMessageSenderId'] as String?;
        // Abaikan pesan yang dikirim oleh diri sendiri
        if (lastSenderId == null || lastSenderId == user.id) continue;
        final ts = data['lastMessageAt'];
        final lastAt = ts is Timestamp ? ts.toDate() : null;
        // Abaikan pesan lama sebelum app dibuka
        if (lastAt == null || lastAt.isBefore(startedAt)) continue;
        final senderName =
            data['lastMessageSenderName'] as String? ?? 'Seseorang';
        final lastText = data['lastMessageText'] as String? ?? '…';
        show(
          title: 'Pesan Baru dari $senderName',
          body: lastText,
        );
      }
    });
  }

  /// Batalkan semua pemantauan Firestore (saat logout / dispose).
  static void cancel() {
    _inboxSub?.cancel();
    _chatSub?.cancel();
    _inboxSub = null;
    _chatSub = null;
  }
}
