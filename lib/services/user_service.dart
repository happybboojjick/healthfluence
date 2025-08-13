// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveOnboarding({
    required String uid,
    required List<String> allergies,
    required List<String> dislikes,
    required List<String> interests,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    await userRef.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await userRef.collection('onboarding').doc('data').set({
      'allergies': allergies,
      'dislikes': dislikes,
      'interests': interests,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Favorites: routines
  Future<void> toggleFavoriteRoutine(String uid, String routineId, bool like) async {
    final ref = _db
        .collection('users').doc(uid)
        .collection('favorites').doc('routines')
        .collection('items').doc(routineId);
    if (like) {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  Stream<List<String>> favoriteRoutineIds(String uid) {
    return _db
        .collection('users').doc(uid)
        .collection('favorites').doc('routines')
        .collection('items').orderBy('createdAt', descending: true).snapshots()
        .map((qs) => qs.docs.map((d) => d.id).toList());
  }

  // Favorites: influencers
  Future<void> toggleFavoriteInfluencer(String uid, String influencerId, bool like) async {
    final ref = _db
        .collection('users').doc(uid)
        .collection('favorites').doc('influencers')
        .collection('items').doc(influencerId);
    if (like) {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  Stream<List<String>> favoriteInfluencerIds(String uid) {
    return _db
        .collection('users').doc(uid)
        .collection('favorites').doc('influencers')
        .collection('items').orderBy('createdAt', descending: true).snapshots()
        .map((qs) => qs.docs.map((d) => d.id).toList());
  }
}
