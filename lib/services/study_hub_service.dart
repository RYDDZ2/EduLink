import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_hub_model.dart';

class StudyHubService {
  StudyHubService._();

  static final _db = FirebaseFirestore.instance;
  static const String _collectionName = 'studyHubs';
  static const String _threadsSubcollection = 'threads';

  // ============= CREATE =============

  static Future<String> createStudyHub({
    required String creatorId,
    required String creatorName,
    required String creatorInitials,
    required String creatorAvatarColor,
    required String title,
    required String description,
    required List<String> tags,
  }) async {
    try {
      final docRef = _db.collection(_collectionName).doc();
      final now = DateTime.now();

      final data = {
        'creatorId': creatorId,
        'creatorName': creatorName,
        'creatorInitials': creatorInitials,
        'creatorAvatarColor': creatorAvatarColor,
        'title': title,
        'description': description,
        'tags': tags,
        'members': 1,
        'activeThreads': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create study hub: $e');
    }
  }

  // ============= READ =============

  static Stream<List<StudyHub>> studyHubsStream({
    String? searchQuery,
    String? tagFilter,
  }) {
    Query query =
        _db.collection(_collectionName).where('status', isEqualTo: 'active');

    return query.snapshots().map((snapshot) {
      var hubs = snapshot.docs
          .map((doc) =>
              StudyHub.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Client-side sorting
      hubs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Client-side filtering untuk search dan tag
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        hubs = hubs.where((hub) {
          return hub.title.toLowerCase().contains(q) ||
              hub.description.toLowerCase().contains(q) ||
              hub.tags.any((tag) => tag.toLowerCase().contains(q));
        }).toList();
      }

      if (tagFilter != null && tagFilter.isNotEmpty) {
        hubs = hubs.where((hub) => hub.tags.contains(tagFilter)).toList();
      }

      return hubs;
    });
  }

  static Stream<List<StudyHub>> myStudyHubsStream(String userId) {
    return _db
        .collection(_collectionName)
        .where('creatorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      var hubs = snapshot.docs
          .map((doc) =>
              StudyHub.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      hubs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return hubs;
    });
  }

  static Future<StudyHub?> getStudyHub(String hubId) async {
    try {
      final doc = await _db.collection(_collectionName).doc(hubId).get();
      if (doc.exists) {
        return StudyHub.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get study hub: $e');
    }
  }

  static Stream<List<StudyHubThread>> threadsStream(String hubId) {
    return _db
        .collection(_collectionName)
        .doc(hubId)
        .collection(_threadsSubcollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudyHubThread.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ============= UPDATE =============

  static Future<void> updateStudyHub(
    String hubId, {
    String? title,
    String? description,
    List<String>? tags,
    StudyHubStatus? status,
    int? members,
    int? activeThreads,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (tags != null) data['tags'] = tags;
      if (status != null) {
        data['status'] =
            status == StudyHubStatus.active ? 'active' : 'archived';
      }
      if (members != null) data['members'] = members;
      if (activeThreads != null) data['activeThreads'] = activeThreads;

      await _db.collection(_collectionName).doc(hubId).update(data);
    } catch (e) {
      throw Exception('Failed to update study hub: $e');
    }
  }

  static Future<void> incrementMembers(String hubId) async {
    try {
      await _db.collection(_collectionName).doc(hubId).update({
        'members': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to increment members: $e');
    }
  }

  static Future<void> decrementMembers(String hubId) async {
    try {
      await _db.collection(_collectionName).doc(hubId).update({
        'members': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to decrement members: $e');
    }
  }

  static Future<void> incrementThreads(String hubId) async {
    try {
      await _db.collection(_collectionName).doc(hubId).update({
        'activeThreads': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to increment threads: $e');
    }
  }

  // ============= DELETE =============

  static Future<void> deleteStudyHub(String hubId) async {
    try {
      // Delete semua threads dalam hub
      final threadsSnapshot = await _db
          .collection(_collectionName)
          .doc(hubId)
          .collection(_threadsSubcollection)
          .get();

      for (var doc in threadsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete hub document
      await _db.collection(_collectionName).doc(hubId).delete();
    } catch (e) {
      throw Exception('Failed to delete study hub: $e');
    }
  }

  static Future<void> archiveStudyHub(String hubId) async {
    try {
      await updateStudyHub(hubId, status: StudyHubStatus.archived);
    } catch (e) {
      throw Exception('Failed to archive study hub: $e');
    }
  }

  // ============= THREAD OPERATIONS =============

  static Future<String> createThread({
    required String hubId,
    required String title,
    required String authorId,
    required String authorName,
    required String authorInitials,
    required String authorAvatarColor,
    required List<String> tags,
  }) async {
    try {
      final docRef = _db
          .collection(_collectionName)
          .doc(hubId)
          .collection(_threadsSubcollection)
          .doc();

      final data = {
        'hubId': hubId,
        'title': title,
        'authorId': authorId,
        'authorName': authorName,
        'authorInitials': authorInitials,
        'authorAvatarColor': authorAvatarColor,
        'tags': tags,
        'replies': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);
      await incrementThreads(hubId);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create thread: $e');
    }
  }

  static Future<void> deleteThread(String hubId, String threadId) async {
    try {
      await _db
          .collection(_collectionName)
          .doc(hubId)
          .collection(_threadsSubcollection)
          .doc(threadId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete thread: $e');
    }
  }

  // ============= REPLY OPERATIONS =============

  static Stream<List<StudyHubReply>> repliesStream(String hubId, String threadId) {
    return _db
        .collection(_collectionName)
        .doc(hubId)
        .collection(_threadsSubcollection)
        .doc(threadId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudyHubReply.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  static Future<String> createReply({
    required String hubId,
    required String threadId,
    required String content,
    required String authorId,
    required String authorName,
    required String authorInitials,
    required String authorAvatarColor,
  }) async {
    try {
      final threadRef = _db
          .collection(_collectionName)
          .doc(hubId)
          .collection(_threadsSubcollection)
          .doc(threadId);

      final replyRef = threadRef.collection('replies').doc();

      final data = {
        'threadId': threadId,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'authorInitials': authorInitials,
        'authorAvatarColor': authorAvatarColor,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _db.runTransaction((transaction) async {
        transaction.set(replyRef, data);
        transaction.update(threadRef, {
          'replies': FieldValue.increment(1),
        });
      });

      return replyRef.id;
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }
}
