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

  Future<void> transitionWorkshopOrder({
    required String orderId,
    required String newStatus,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || orderId.isEmpty || orderId.contains('/')) {
      throw const WorkshopWorkflowException(
        'يرجى تسجيل الدخول والتحقق من الطلب.',
      );
    }
    final ref = _firestore.collection('orders').doc(orderId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final profile = await tx.get(_firestore.collection('users').doc(uid));
      final order = snapshot.data();
      if (_auth.currentUser?.uid != uid ||
          order == null ||
          profile.data()?['role'] != 'workshop') {
        throw const WorkshopWorkflowException(
          'الطلب غير موجود أو الحساب غير مخوّل كورشة.',
        );
      }
      if (order['status'] == 'pending' &&
          order['workshopId'] == 'all' &&
          ['accepted', 'refused'].contains(newStatus)) {
        tx.update(ref, {
          'status': newStatus,
          if (newStatus == 'accepted') 'workshopId': uid,
        });
        return;
      }
      Map<String, dynamic>? report;
      if (['inspecting', 'fixing'].contains(order['status'])) {
        final reportId = order['inspectionReportId'];
        if (reportId is! String || reportId.isEmpty || reportId.contains('/')) {
          throw const WorkshopWorkflowException(
            'لم يُحفظ تقرير فحص مرتبط بهذا الطلب.',
          );
        }
        report = (await tx.get(
          ref.collection('inspectionReports').doc(reportId),
        )).data();
      }
      WorkshopWorkflow.validate(
        order: order,
        report: report,
        orderId: orderId,
        uid: uid,
        newStatus: newStatus,
      );
      tx.update(ref, {
        'status': newStatus,
        if (newStatus == 'completed')
          'completedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ─── تحديث حالة الأوردر ──────────────────────────────────────
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    await transitionWorkshopOrder(orderId: orderId, newStatus: newStatus);
  }
}

class WorkshopWorkflowException implements Exception {
  final String message;
  const WorkshopWorkflowException(this.message);
}

/// Shared by the UI and the transaction. Not server-enforced authorization.
class WorkshopWorkflow {
  static bool reviewedRepairs({
    required Map<String, dynamic> order,
    required Map<String, dynamic>? report,
    required String orderId,
    required String uid,
  }) {
    if (order['inspectionReportId'] is! String ||
        (order['inspectionReportId'] as String).isEmpty ||
        report == null ||
        report['orderId'] != orderId ||
        report['workshopId'] != uid ||
        order['inspectionStatus'] != 'reviewed' ||
        report['status'] != 'reviewed') {
      throw const WorkshopWorkflowException(
        'يلزم تقرير مرتبط تمت مراجعته بعد اكتمال قرارات الزبون.',
      );
    }
    final raw = report['items'];
    if (raw is! List || raw.isEmpty) {
      throw const WorkshopWorkflowException('بيانات قطع التقرير غير مكتملة.');
    }
    final ids = <String>{};
    var approved = false;
    for (final entry in raw) {
      if (entry is! Map) {
        throw const WorkshopWorkflowException('بيانات إحدى القطع غير صالحة.');
      }
      final id = entry['id'],
          condition = entry['condition'],
          decision = entry['approvalStatus'];
      final price = entry['partPrice'], labor = entry['laborCost'];
      if (id is! String ||
          id.trim().isEmpty ||
          !ids.add(id) ||
          !['red', 'orange', 'green'].contains(condition) ||
          price is! num ||
          labor is! num ||
          !price.isFinite ||
          !labor.isFinite ||
          price < 0 ||
          labor < 0 ||
          !(price + labor).isFinite ||
          (condition == 'green' &&
              (decision != 'notRequired' || price != 0 || labor != 0)) ||
          (condition != 'green' &&
              !['approved', 'rejected'].contains(decision))) {
        throw const WorkshopWorkflowException(
          'بانتظار قرارات الزبون أو توجد بيانات غير صالحة في التقرير.',
        );
      }
      if (condition != 'green' && decision == 'approved') approved = true;
    }
    return approved;
  }

  static String? nextStatus({
    required Map<String, dynamic> order,
    required Map<String, dynamic>? report,
    required String orderId,
    required String uid,
  }) {
    if (uid.isEmpty || order['workshopId'] != uid) {
      throw const WorkshopWorkflowException('هذا الطلب غير تابع لورشتك.');
    }
    switch (order['status']) {
      case 'accepted':
        return 'inspecting';
      case 'inspecting':
        return reviewedRepairs(
              order: order,
              report: report,
              orderId: orderId,
              uid: uid,
            )
            ? 'fixing'
            : 'completed';
      case 'fixing':
        if (!reviewedRepairs(
          order: order,
          report: report,
          orderId: orderId,
          uid: uid,
        )) {
          throw const WorkshopWorkflowException(
            'لا توجد إصلاحات موافق عليها لإنهاء الإصلاح.',
          );
        }
        return 'completed';
      // Compatibility only: the latest stored order must already be ready.
      // No application transition is allowed to enter ready.
      case 'ready':
        return 'completed';
      case 'completed':
        return null;
      default:
        throw const WorkshopWorkflowException(
          'لا يوجد انتقال صيانة متاح لهذه الحالة.',
        );
    }
  }

  static void validate({
    required Map<String, dynamic> order,
    required Map<String, dynamic>? report,
    required String orderId,
    required String uid,
    required String newStatus,
  }) {
    if (newStatus == 'ready' ||
        nextStatus(order: order, report: report, orderId: orderId, uid: uid) !=
            newStatus) {
      throw const WorkshopWorkflowException(
        'انتقال غير مسموح أو تغيّرت حالة الطلب. حدّث الشاشة.',
      );
    }
  }
}
