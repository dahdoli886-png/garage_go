import 'package:flutter/material.dart';
import '../models/inspection_item_model.dart';
import '../models/inspection_report_model.dart';
import '../services/inspection_service.dart';

class InspectionReportDetailsScreen extends StatefulWidget {
  final String orderId;
  final String reportId;

  const InspectionReportDetailsScreen({
    super.key,
    required this.orderId,
    required this.reportId,
  });

  @override
  State<InspectionReportDetailsScreen> createState() =>
      _InspectionReportDetailsScreenState();
}

class _InspectionReportDetailsScreenState
    extends State<InspectionReportDetailsScreen> {
  late final Stream<InspectionReport?> _reportStream;

  @override
  void initState() {
    super.initState();
    _reportStream = InspectionService().watchReport(
      orderId: widget.orderId,
      reportId: widget.reportId,
    );
  }

  Color _color(PartCondition condition) => switch (condition) {
    PartCondition.red => const Color(0xFFEF4444),
    PartCondition.orange => const Color(0xFFF59E0B),
    PartCondition.green => const Color(0xFF10B981),
  };

  String _condition(PartCondition condition) => switch (condition) {
    PartCondition.red => '🔴 خطيرة - تحتاج إصلاح عاجل',
    PartCondition.orange => '🟠 مستهلكة - يُنصح بتغييرها',
    PartCondition.green => '🟢 سليمة - للمعلومات فقط',
  };

  String _approval(PartApprovalStatus status) => switch (status) {
    PartApprovalStatus.pending => 'بانتظار موافقة الزبون',
    PartApprovalStatus.approved => 'وافق الزبون على الإصلاح',
    PartApprovalStatus.rejected => 'رفض الزبون الإصلاح',
    PartApprovalStatus.notRequired => 'لا تتطلب موافقة',
  };

  String _status(InspectionReportStatus status) => switch (status) {
    InspectionReportStatus.draft => 'مسودة',
    InspectionReportStatus.awaitingApproval => 'بانتظار موافقة الزبون',
    InspectionReportStatus.reviewed => 'تمت المراجعة',
  };

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFF070D18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: const Color(0xFFE8EDF5),
        title: const Text('📋 تقرير الفحص'),
      ),
      body: StreamBuilder<InspectionReport?>(
        stream: _reportStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'تعذر تحميل التقرير. تحقق من الاتصال وصلاحيات الوصول.',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = snapshot.data;
          if (report == null) {
            return const Center(
              child: Text(
                'لم يتم العثور على تقرير الفحص.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('رقم الطلب: ${report.orderId}'),
                    Text('رقم التقرير: ${report.id}'),
                    Text('الحالة: ${_status(report.status)}'),
                  ],
                ),
              ),
              ...report.items.map(
                (item) => _panel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: _color(item.condition),
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(_condition(item.condition)),
                      Text(_approval(item.approvalStatus)),
                      Text(
                        item.condition == PartCondition.green
                            ? 'قطعة سليمة للمعلومات فقط'
                            : item.approvalStatus == PartApprovalStatus.approved
                            ? 'إصلاحات مسموح تنفيذها'
                            : item.approvalStatus == PartApprovalStatus.rejected
                            ? 'إصلاحات مرفوضة – لا تُنفذ'
                            : 'إصلاح معلّق – لا يُنفذ قبل الموافقة',
                      ),
                      if (item.notes.isNotEmpty) Text(item.notes),
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Image.network(
                            item.imageUrl!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Text('تعذر عرض الصورة'),
                          ),
                        ),
                      Text(
                        'سعر القطعة: ${item.partPrice.toStringAsFixed(2)} د.أ',
                      ),
                      Text(
                        'أجرة العمل: ${item.laborCost.toStringAsFixed(2)} د.أ',
                      ),
                      Text('المجموع: ${item.totalCost.toStringAsFixed(2)} د.أ'),
                    ],
                  ),
                ),
              ),
              _panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التكلفة التقديرية: ${report.totalEstimatedCost.toStringAsFixed(2)} د.أ',
                    ),
                    Text(
                      'الإصلاحات الموافق عليها فقط: ${report.totalApprovedCost.toStringAsFixed(2)} د.أ',
                    ),
                    if (report.status == InspectionReportStatus.reviewed &&
                        !report.items.any(
                          (item) =>
                              item.requiresApproval &&
                              item.approvalStatus ==
                                  PartApprovalStatus.approved,
                        ))
                      const Text('لا توجد إصلاحات وافق عليها الزبون'),
                    const Text(
                      'الإصلاحات المرفوضة أو التي تنتظر الموافقة لا تدخل في مبلغ الفوترة.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _panel(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1B2A),
      border: Border.all(color: const Color(0xFF1E3A5F)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: DefaultTextStyle(
      style: const TextStyle(color: Color(0xFFE8EDF5), height: 1.7),
      child: child,
    ),
  );
}
