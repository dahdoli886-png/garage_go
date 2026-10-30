import 'package:cloud_firestore/cloud_firestore.dart';
import 'inspection_item_model.dart';

enum InspectionReportStatus { draft, awaitingApproval, reviewed }

class InspectionReport {
  final String id;
  final String orderId;
  final String workshopId;
  final List<InspectionItem> items;
  final InspectionReportStatus status;
  final DateTime createdAt;

  const InspectionReport({
    required this.id,
    required this.orderId,
    required this.workshopId,
    required this.items,
    required this.status,
    required this.createdAt,
  });

  // التكلفة التقديرية لجميع القطع
  double get totalEstimatedCost {
    return items.fold(0.0, (total, item) => total + item.totalCost);
  }

  // تكلفة القطع التي وافق عليها الزبون فقط
  double get totalApprovedCost {
    return items
        .where(
          (item) =>
              item.requiresApproval &&
              item.approvalStatus == PartApprovalStatus.approved,
        )
        .fold(0.0, (total, item) => total + item.totalCost);
  }

  // تحويل التقرير إلى بيانات قابلة للتخزين في Firestore
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'workshopId': workshopId,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // تحويل بيانات Firestore إلى InspectionReport
  factory InspectionReport.fromMap(String id, Map<String, dynamic> data) {
    final statusName = data['status'] as String? ?? 'draft';

    return InspectionReport(
      id: id,
      orderId: data['orderId'] as String? ?? '',
      workshopId: data['workshopId'] as String? ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                InspectionItem.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      status: InspectionReportStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => InspectionReportStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
