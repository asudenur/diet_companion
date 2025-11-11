import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _docIdForDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Stream<int> todayTotalMlStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream<int>.empty();
    final id = _docIdForDay(DateTime.now());
    return _db
        .collection('users')
        .doc(uid)
        .collection('water')
        .doc(id)
        .snapshots()
        .map((doc) => (doc.data()?['totalMl'] ?? 0) as int);
  }

  Future<void> addWater(int amountMl) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    final id = _docIdForDay(DateTime.now());
    final ref = _db.collection('users').doc(uid).collection('water').doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['totalMl'] ?? 0) as int;
      tx.set(ref, {
        'totalMl': current + amountMl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> resetToday() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    final id = _docIdForDay(DateTime.now());
    final ref = _db.collection('users').doc(uid).collection('water').doc(id);
    await ref.set({'totalMl': 0, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
}
