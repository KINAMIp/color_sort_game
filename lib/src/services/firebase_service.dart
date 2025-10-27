import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class LeaderboardEntry {
  LeaderboardEntry({
    required this.userId,
    required this.levelId,
    required this.stars,
    required this.timestamp,
  });

  final String userId;
  final String levelId;
  final int stars;
  final DateTime timestamp;
}

class FirebaseService {
  bool _initialized = false;
  bool _available = true;

  FirebaseAuth? get _auth => _initialized ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore => _initialized ? FirebaseFirestore.instance : null;

  bool get isAvailable => _available && _initialized;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (error) {
      _available = false;
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    if (!isAvailable) {
      return null;
    }
    return _auth?.signInAnonymously();
  }

  Future<void> saveProgress({
    required String userId,
    required String levelId,
    required int stars,
  }) async {
    if (!isAvailable) {
      return;
    }
    final doc = _firestore!
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(levelId);
    await doc.set(<String, dynamic>{
      'stars': stars,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<LeaderboardEntry>> leaderboardStream(String levelId) {
    if (!isAvailable) {
      return const Stream<List<LeaderboardEntry>>.empty();
    }
    return _firestore!
        .collection('leaderboards')
        .doc(levelId)
        .collection('scores')
        .orderBy('stars', descending: true)
        .orderBy('updatedAt', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LeaderboardEntry(
          userId: data['userId'] as String? ?? 'unknown',
          levelId: levelId,
          stars: (data['stars'] as num?)?.toInt() ?? 0,
          timestamp: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }
}
