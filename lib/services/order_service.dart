import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── جيب أوردرات المستخدم الحالي ────────────────────────────
  Stream<QuerySnapshot> getMyOrders() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('serviceOrders')
        .where('customerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─── إضافة أوردر جديد ────────────────────────────────────────
  Future<void> addOrder({
    required String carModel,
    required String issueDescription,
    required bool remotePickup,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('serviceOrders').add({
      'customerId': uid,
      'carModel': carModel,
      'issueDescription': issueDescription,
      'status': 'pending',
      'remotePickup': remotePickup,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── تحديث حالة الأوردر ──────────────────────────────────────
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    await _firestore
        .collection('serviceOrders')
        .doc(orderId)
        .update({'status': newStatus});
  }
}