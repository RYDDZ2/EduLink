import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking_model.dart';
import '../models/help_request_model.dart';
import '../models/marketplace_models.dart';
import '../models/tutor_session_model.dart';
import '../models/user_model.dart';

class MarketplaceService {
  MarketplaceService._();

  static final _db = FirebaseFirestore.instance;

  static Stream<List<HelpRequest>> helpRequests() {
    return _db
        .collection('helpRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HelpRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  static Stream<List<TutorSession>> tutorSessions() {
    return _db
        .collection('tutorSessions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TutorSession.fromMap(doc.id, doc.data()))
            .toList());
  }

  static Stream<List<HelpOffer>> offersForStudent(String studentId) {
    return _db
        .collection('helpOffers')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => _sortByCreatedDesc(snapshot.docs
            .map((doc) => HelpOffer.fromMap(doc.id, doc.data()))
            .toList()));
  }

  static Stream<List<SessionBookingRequest>> bookingsForTutor(String tutorId) {
    return _db
        .collection('sessionBookings')
        .where('tutorId', isEqualTo: tutorId)
        .snapshots()
        .map((snapshot) => _sortBookingsDesc(snapshot.docs
            .map((doc) => SessionBookingRequest.fromMap(doc.id, doc.data()))
            .toList()));
  }

  static Stream<List<TutoringSession>> tutoringSessionsForUser(String userId) {
    return _db
        .collection('tutoringSessions')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => TutoringSession.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return items;
    });
  }

  static Stream<List<ChatMessage>> messages(String sessionId) {
    return _db
        .collection('tutoringSessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  static Future<void> createHelpRequest(HelpRequest request) {
    return _db.collection('helpRequests').add({
      ...request.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createTutorSession(TutorSession session) async {
    final existing = await _db
        .collection('tutorSessions')
        .where('tutorId', isEqualTo: session.tutorId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Tutor hanya boleh memiliki 1 sesi tutor aktif.');
    }

    await _db.collection('tutorSessions').add(session.toMap());
  }

  static Future<void> updateTutorSession(TutorSession session) {
    return _db
        .collection('tutorSessions')
        .doc(session.id)
        .update(session.toMap());
  }

  static Future<void> deleteTutorSession(String id) {
    return _db.collection('tutorSessions').doc(id).delete();
  }

  static Future<void> updateHelpRequest(HelpRequest request) {
    return _db
        .collection('helpRequests')
        .doc(request.id)
        .update(request.toMap());
  }

  static Future<void> deleteHelpRequest(String id) {
    return _db.collection('helpRequests').doc(id).delete();
  }

  static Future<void> offerHelp({
    required HelpRequest request,
    required AppUser tutor,
    String message = '',
  }) async {
    final duplicate = await _db
        .collection('helpOffers')
        .where('requestId', isEqualTo: request.id)
        .where('tutorId', isEqualTo: tutor.id)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) return;

    await _db.collection('helpOffers').add({
      'requestId': request.id,
      'requestTitle': request.title,
      'studentId': request.userId,
      'studentName': request.userName,
      'tutorId': tutor.id,
      'tutorName': tutor.name,
      'tutorInitials': tutor.initials,
      'tutorAvatarColor': '#E1F5EE',
      'message': message,
      'status': 'pending',
      'kpOffered': request.knowledgePoints,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db
        .collection('helpRequests')
        .doc(request.id)
        .update({'status': 'pending'});
  }

  static Future<void> acceptOffer(HelpOffer offer, AppUser student) async {
    final sessionRef = _db.collection('tutoringSessions').doc();
    final batch = _db.batch();

    batch.set(sessionRef, {
      'studentId': offer.studentId,
      'studentName': offer.studentName,
      'studentInitials': student.initials,
      'tutorId': offer.tutorId,
      'tutorName': offer.tutorName,
      'tutorInitials': offer.tutorInitials,
      'title': offer.requestTitle,
      'subject': offer.requestTitle,
      'sourceType': 'offer',
      'sourceId': offer.id,
      'participants': [offer.studentId, offer.tutorId],
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
      'kpAwarded': offer.kpOffered,
      'kpStudentAwarded': offer.kpOffered,
      'kpTutorAwarded': offer.kpOffered,
    });
    batch.update(_db.collection('helpOffers').doc(offer.id), {
      'status': 'accepted',
    });
    batch.update(_db.collection('helpRequests').doc(offer.requestId), {
      'status': 'confirmed',
    });
    // KP rule (fix):
    // - Tutor menerima KP yang ditawarkan student melalui helpOffers
    // - Student menerima KP yang ditawarkan tutor melalui helpOffers
    // Untuk saat ini, helpOffer menyimpan kpOffered dari request => itu adalah KP yang diminta student.
    batch.update(_db.collection('users').doc(offer.tutorId), {
      'knowledgePoints': FieldValue.increment(offer.kpOffered),
    });

    // Student KP harusnya didapat dari kp yang ditawarkan tutor saat tutor accept.
    // Karena field tersebut belum ada, fallback: gunakan kpOffered juga agar tidak nol.
    // (akan saya tambah field dedicated tutorOfferedKp utk remove ambiguity sepenuhnya)
    batch.update(_db.collection('users').doc(offer.studentId), {
      'knowledgePoints': FieldValue.increment(offer.kpOffered),
    });

    await batch.commit();
  }

  static Future<void> createBookingRequest({
    required AppUser student,
    required TutorSession tutor,
    required Booking booking,
  }) {
    return _db.collection('sessionBookings').add({
      'tutorSessionId': tutor.id,
      'tutorId': tutor.tutorId,
      'tutorName': tutor.tutorName,
      'studentId': student.id,
      'studentName': student.name,
      'studentInitials': student.initials,
      'subject': booking.subject,
      'scheduledAt': Timestamp.fromDate(booking.scheduledAt),
      'durationMinutes': booking.durationMinutes,
      'kpCost': booking.kpCost,
      'tutorKp': tutor.kp,
      'notes': booking.notes ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> acceptBooking(SessionBookingRequest booking) async {
    final sessionRef = _db.collection('tutoringSessions').doc();
    final batch = _db.batch();

    // Rule (fix):
    // - KP yang ditawarkan tutor = booking.kpCost (ditulis oleh student sebagai kpCost yang bayar ke tutor)
    // - KP yang ditawarkan student untuk tutor = tutor.kp (field TutorSession.kp)
    // Di current flow, marketplace_models.SessionBookingRequest belum membawa tutor.kp,
    // sehingga kita pakai fallback: kpCost untuk student award juga.

    final kpStudentGets = booking.kpCost;
    final kpTutorGets = booking.tutorKp > 0 ? booking.tutorKp : booking.kpCost;

    batch.set(sessionRef, {
      'studentId': booking.studentId,
      'studentName': booking.studentName,
      'studentInitials': booking.studentInitials,
      'tutorId': booking.tutorId,
      'tutorName': booking.tutorName,
      'tutorInitials': _initials(booking.tutorName),
      'title': 'Sesi ${booking.subject}',
      'subject': booking.subject,
      'sourceType': 'booking',
      'sourceId': booking.id,
      'participants': [booking.studentId, booking.tutorId],
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
      'kpAwarded': kpStudentGets,
      'kpStudentAwarded': kpStudentGets,
      'kpTutorAwarded': kpTutorGets,
    });

    batch.update(_db.collection('sessionBookings').doc(booking.id), {
      'status': 'accepted',
    });
    // Award KP after session assigned:
    // - Student gets KP yang ditawarkan tutor (fallback saat ini: kpCost)
    // - Tutor gets KP yang ditawarkan student (fallback saat ini: kpCost)

    batch.update(_db.collection('users').doc(booking.studentId), {
      'knowledgePoints': FieldValue.increment(kpStudentGets),
    });
    batch.update(_db.collection('users').doc(booking.tutorId), {
      'knowledgePoints': FieldValue.increment(kpTutorGets),
    });

    await batch.commit();
  }

  static Future<void> declineBooking(String bookingId) {
    return _db.collection('sessionBookings').doc(bookingId).update({
      'status': 'declined',
    });
  }

  static Future<void> sendMessage({
    required String sessionId,
    required AppUser sender,
    required String text,
  }) {
    return _db
        .collection('tutoringSessions')
        .doc(sessionId)
        .collection('messages')
        .add({
      'senderId': sender.id,
      'senderName': sender.name,
      'text': text.trim(),
      'attachmentType': null,
      'attachmentUrl': null,
      'attachmentName': null,
      'attachmentMime': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendMessageImage({
    required String sessionId,
    required AppUser sender,
    required String text,
    required String imageUrl,
    required String imageName,
    String? mime,
  }) {
    return _db
        .collection('tutoringSessions')
        .doc(sessionId)
        .collection('messages')
        .add({
      'senderId': sender.id,
      'senderName': sender.name,
      'text': text.trim(),
      'attachmentType': 'image',
      'attachmentUrl': imageUrl,
      'attachmentName': imageName,
      'attachmentMime': mime,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendMessageDoc({
    required String sessionId,
    required AppUser sender,
    required String text,
    required String docUrl,
    required String docName,
    String? mime,
  }) {
    return _db
        .collection('tutoringSessions')
        .doc(sessionId)
        .collection('messages')
        .add({
      'senderId': sender.id,
      'senderName': sender.name,
      'text': text.trim(),
      'attachmentType': 'doc',
      'attachmentUrl': docUrl,
      'attachmentName': docName,
      'attachmentMime': mime,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> endSession(String sessionId) {
    return _db.collection('tutoringSessions').doc(sessionId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rateTutor({
    required TutorSession tutor,
    required AppUser student,
    required int rating,
  }) async {
    final ratingRef = _db
        .collection('tutorSessions')
        .doc(tutor.id)
        .collection('ratings')
        .doc(student.id);
    final tutorRef = _db.collection('tutorSessions').doc(tutor.id);

    await _db.runTransaction((transaction) async {
      final tutorSnap = await transaction.get(tutorRef);
      if (!tutorSnap.exists) return;

      final ratingSnap = await transaction.get(ratingRef);
      final data = tutorSnap.data() ?? {};
      final oldAverage = (data['rating'] as num?)?.toDouble() ?? 0;
      final oldCount = data['reviewCount'] as int? ?? 0;
      final previousRating = ratingSnap.data()?['rating'] as int?;

      final nextCount = previousRating == null ? oldCount + 1 : oldCount;
      final total = oldAverage * oldCount - (previousRating ?? 0) + rating;
      final nextAverage =
          nextCount == 0 ? rating.toDouble() : total / nextCount;

      transaction.set(ratingRef, {
        'studentId': student.id,
        'studentName': student.name,
        'rating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(tutorRef, {
        'rating': nextAverage,
        'reviewCount': nextCount,
      });
    });
  }

  static List<HelpOffer> _sortByCreatedDesc(List<HelpOffer> items) {
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static List<SessionBookingRequest> _sortBookingsDesc(
    List<SessionBookingRequest> items,
  ) {
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'TR';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
