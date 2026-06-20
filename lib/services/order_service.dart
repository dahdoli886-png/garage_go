import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── جيب أوردرات المستخدم الحالي (العميل) ────────────────────────────
  Stream<QuerySnapshot> getMyOrders() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─── إضافة أوردر جديد (متاح لكل الورشات) ─────────────────────────────
  Future<void> addOrder({
    required String customerName,
    required String carBrand,
    required String carModel,
    required String faultType,
    required String issueDescription,
    required bool remotePickup,
  }) async {
    final uid = _auth.currentUser!.uid;

    // إرسال الطلب لـ collection 'orders'
    await _firestore.collection('orders').add({
      'customerId': uid,
      'customerName': customerName,
      'carBrand': carBrand,
      'carModel': carModel,
      'faultType': faultType,
      'description': issueDescription,
      'status': 'pending',
      'remotePickup': remotePickup,
      'workshopId': 'all', // 🚀 الطلب متاح لكل الورشات
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── تحديث حالة الأوردر ──────────────────────────────────────
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    await _firestore
        .collection('orders') // 🚀 تم التعديل هنا (كانت serviceOrders)
        .doc(orderId)
        .update({'status': newStatus});
  }
}
