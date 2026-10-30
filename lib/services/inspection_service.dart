import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inspection_item_model.dart';
import '../models/inspection_report_model.dart';

class InspectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _reports(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('inspectionReports');
  }

  static InspectionReportStatus initialReportStatus(
    List<InspectionItem> items,
  ) => items.any((item) => item.requiresApproval)
      ? InspectionReportStatus.awaitingApproval
      : InspectionReportStatus.reviewed;

  // حفظ تقرير جديد وإرساله للزبون
  Future<String> createReport({
    required String orderId,
    required List<InspectionItem> items,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in first.');
    }

    if (items.isEmpty) {
      throw ArgumentError('Add at least one inspection item.');
    }

    // التحقق من صحة بيانات القطع
    final itemIds = <String>{};

    for (final item in items) {
      if (item.id.trim().isEmpty || item.name.trim().isEmpty) {
        throw ArgumentError('Each inspection item needs an ID and name.');
      }

      if (!itemIds.add(item.id)) {
        throw ArgumentError('Duplicate inspection item ID: ${item.id}');
      }

      if (!item.partPrice.isFinite ||
          !item.laborCost.isFinite ||
          item.partPrice < 0 ||
          item.laborCost < 0) {
        throw ArgumentError('Prices must be valid and non-negative.');
      }

      final expectedStatus = item.requiresApproval
          ? PartApprovalStatus.pending
          : PartApprovalStatus.notRequired;

      if (item.approvalStatus != expectedStatus) {
        throw StateError('Invalid initial approval status for ${item.name}.');
      }

      if (!item.requiresApproval && item.totalCost != 0) {
        throw StateError('Healthy items cannot have repair charges.');
      }
    }

    final initialStatus = initialReportStatus(items);
    final orderRef = _firestore.collection('orders').doc(orderId);

    final reportRef = _reports(orderId).doc();

    // استخدام Transaction لضمان عدم إنشاء تقريرين
    // لنفس الطلب عند إرسال طلبين بنفس الوقت
    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);

      if (!orderSnapshot.exists) {
        throw StateError('Order not found.');
      }

      final order = orderSnapshot.data()!;

      // التأكد أن الورشة مسؤولة عن الطلب
      if (order['workshopId'] != user.uid) {
        throw StateError('You are not assigned to this order.');
      }

      // يجب أن يكون الطلب في مرحلة الفحص
      if (order['status'] != 'inspecting') {
        throw StateError('Order must be in inspecting status.');
      }

      // منع إنشاء تقرير جديد إذا كان تقرير موجود
      final existingReportId = order['inspectionReportId'];

      if (existingReportId is String && existingReportId.isNotEmpty) {
        throw StateError('An inspection report already exists for this order.');
      }

      // إنشاء تقرير الفحص
      final report = InspectionReport(
        id: reportRef.id,
        orderId: orderId,
        workshopId: user.uid,
        items: items,
        status: initialStatus,
        createdAt: DateTime.now(),
      );

      // حفظ التقرير
      transaction.set(reportRef, report.toMap());

      // ربط التقرير بالطلب
      transaction.update(orderRef, {
        'inspectionReportId': reportRef.id,
        'inspectionStatus': initialStatus.name,
      });
    });

    return reportRef.id;
  }

  /// Application-level checks only; open Firestore Rules still allow bypasses.
  Future<void> decideItem({
    required String orderId,
    required String reportId,
    required String itemId,
    required PartApprovalStatus decision,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const InspectionDecisionException('يرجى تسجيل الدخول مجدداً.');
    }
    if ([
      orderId,
      reportId,
      itemId,
    ].any((id) => id.trim().isEmpty || id.contains('/'))) {
      throw const InspectionDecisionException(
        'معرّفات الطلب أو التقرير أو القطعة غير صالحة.',
      );
    }
    final orderRef = _firestore.collection('orders').doc(orderId);
    final reportRef = _reports(orderId).doc(reportId);
    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final reportSnapshot = await transaction.get(reportRef);
      final order = orderSnapshot.data();
      final report = reportSnapshot.data();
      if (_auth.currentUser?.uid != uid || order == null || report == null) {
        throw const InspectionDecisionException(
          'الطلب أو التقرير غير موجود، أو تغيّرت جلسة الدخول.',
        );
      }
      if (order['customerId'] != uid) {
        throw const InspectionDecisionException(
          'لا يمكنك اتخاذ قرار لطلب تابع لمستخدم آخر.',
        );
      }
      if (order['inspectionReportId'] != reportId ||
          report['orderId'] != orderId ||
          report['workshopId'] is! String ||
          report['workshopId'] == 'all' ||
          report['workshopId'] != order['workshopId']) {
        throw const InspectionDecisionException(
          'بيانات ربط تقرير الفحص غير متطابقة.',
        );
      }
      if (!['inspecting', 'pending_approval'].contains(order['status']) ||
          order['inspectionStatus'] != 'awaitingApproval' ||
          report['status'] != 'awaitingApproval') {
        throw const InspectionDecisionException(
          'التقرير لم يعد متاحاً لاتخاذ القرارات.',
        );
      }
      final result = prepareItemDecision(
        rawItems: report['items'],
        itemId: itemId,
        decision: decision,
      );
      final status = result.reviewed ? 'reviewed' : 'awaitingApproval';
      transaction.update(reportRef, {'items': result.items, 'status': status});
      transaction.update(orderRef, {'inspectionStatus': status});
    });
  }

  /// Uses server-read maps so unknown fields and all unrelated values survive.
  static InspectionDecisionResult prepareItemDecision({
    required Object? rawItems,
    required String itemId,
    required PartApprovalStatus decision,
  }) {
    if (![
      PartApprovalStatus.approved,
      PartApprovalStatus.rejected,
    ].contains(decision)) {
      throw const InspectionDecisionException('اختر الموافقة أو الرفض فقط.');
    }
    if (rawItems is! List || rawItems.isEmpty) {
      throw const InspectionDecisionException('بيانات قطع التقرير غير مكتملة.');
    }
    final ids = <String>{};
    final items = <Map<String, dynamic>>[];
    for (final raw in rawItems) {
      if (raw is! Map || raw.keys.any((key) => key is! String)) {
        throw const InspectionDecisionException('بيانات إحدى القطع غير صالحة.');
      }
      final item = Map<String, dynamic>.from(raw);
      final id = item['id'];
      final condition = item['condition'];
      final approval = item['approvalStatus'];
      final price = item['partPrice'];
      final labor = item['laborCost'];
      if (id is! String ||
          id.trim().isEmpty ||
          !ids.add(id) ||
          !['red', 'orange', 'green'].contains(condition) ||
          ![
            'pending',
            'approved',
            'rejected',
            'notRequired',
          ].contains(approval) ||
          price is! num ||
          labor is! num ||
          !price.isFinite ||
          !labor.isFinite ||
          price < 0 ||
          labor < 0 ||
          !(price + labor).isFinite ||
          (condition == 'green' &&
              (price != 0 || labor != 0 || approval != 'notRequired')) ||
          (condition != 'green' && approval == 'notRequired')) {
        throw const InspectionDecisionException(
          'بيانات التقرير قديمة أو غير صالحة. يرجى مراجعة الورشة.',
        );
      }
      items.add(item);
    }
    final index = items.indexWhere((item) => item['id'] == itemId);
    if (index < 0) {
      throw const InspectionDecisionException('القطعة المطلوبة غير موجودة.');
    }
    final selected = items[index];
    if (selected['condition'] == 'green') {
      throw const InspectionDecisionException(
        'القطعة السليمة لا تتطلب قرار إصلاح.',
      );
    }
    if (selected['approvalStatus'] != 'pending') {
      throw const InspectionDecisionException(
        'تم اتخاذ قرار لهذه القطعة بالفعل.',
      );
    }
    selected['approvalStatus'] = decision.name;
    final reviewed = !items.any(
      (item) =>
          ['red', 'orange'].contains(item['condition']) &&
          item['approvalStatus'] == 'pending',
    );
    return InspectionDecisionResult(items: items, reviewed: reviewed);
  }

  // جلب تقرير فحص محدد
  Future<InspectionReport?> getReport({
    required String orderId,
    required String reportId,
  }) async {
    final snapshot = await _reports(orderId).doc(reportId).get();

    if (!snapshot.exists) {
      return null;
    }

    return InspectionReport.fromMap(snapshot.id, snapshot.data()!);
  }

  // متابعة تقرير الفحص مباشرة من Firestore
  Stream<InspectionReport?> watchReport({
    required String orderId,
    required String reportId,
  }) {
    return _reports(orderId).doc(reportId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return InspectionReport.fromMap(snapshot.id, snapshot.data()!);
    });
  }
}

class InspectionDecisionException implements Exception {
  final String message;
  const InspectionDecisionException(this.message);
}

class InspectionDecisionResult {
  final List<Map<String, dynamic>> items;
  final bool reviewed;
  const InspectionDecisionResult({required this.items, required this.reviewed});
}
