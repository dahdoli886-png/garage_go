import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart' show DateFormat;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inspection_item_model.dart';
import '../models/inspection_report_model.dart';
import '../services/inspection_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String get orderId => widget.orderId;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('[OrderDetails] orderId: $orderId');
      debugPrint(
        '[OrderDetails] projectId: ${Firebase.app().options.projectId}',
      );
      debugPrint('[OrderDetails] documentPath: orders/$orderId');
    }
  }

  // دوال مساعدة لحالة الطلبات
  // ─── دوال مساعدة لترجمة حالة الطلب وتحديد اللون ────────────────
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green; // 🚀 أضفنا حالة القبول باللون الأخضر
      case 'refused':
        return Colors.redAccent; // 🚀 أضفنا حالة الرفض باللون الأحمر
      case 'driver_assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.purple;
      case 'inspecting':
        return Colors.indigo;
      case 'pending_approval':
        return Colors.amber;
      case 'fixing':
        return Colors.teal;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'بانتظار القبول';
      case 'accepted':
        return 'مقبول'; // 🚀 ترجمة accepted
      case 'refused':
        return 'مرفوض'; // 🚀 ترجمة refused
      case 'driver_assigned':
        return 'تم تعيين سائق';
      case 'picked_up':
        return 'تم الاستلام';
      case 'inspecting':
        return 'قيد الفحص';
      case 'pending_approval':
        return 'بانتظار موافقتك';
      case 'fixing':
        return 'قيد الإصلاح';
      case 'ready':
        return 'جاهز للتسليم (طلب قديم)';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status; // في حال ظهرت حالة جديدة غير مسجلة
    }
  }

  // دالة لإلغاء الطلب
  Future<void> _cancelOrder(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3E53),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text(
              'إلغاء الطلب',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .update({'status': 'cancelled'});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إلغاء الطلب'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text(
              'نعم، إلغاء',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        appBar: AppBar(
          title: const Text(
            'تفاصيل الطلب',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            if (authSnapshot.hasError || user == null) {
              return const Center(
                child: Text(
                  'يرجى تسجيل الدخول لعرض تفاصيل الطلب.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return StreamBuilder<DocumentSnapshot>(
              key: ValueKey('$orderId:${user.uid}'),
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'تعذر تحميل الطلب. تحقق من الاتصال وصلاحيات الوصول.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      'الطلب غير موجود',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                // Client-side display guard; Firestore Rules must enforce access too.
                if (data['customerId'] != user.uid) {
                  return const Center(
                    child: Text(
                      'لا يمكنك عرض تفاصيل طلب تابع لمستخدم آخر.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                final reportId = data['inspectionReportId'];
                final status = data['status'] ?? 'pending';
                final createdAt = data['createdAt'] as Timestamp?;
                final dateString = createdAt != null
                    ? DateFormat(
                        'yyyy-MM-dd / hh:mm a',
                      ).format(createdAt.toDate())
                    : 'غير متوفر';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. بطاقة الحالة العلوية
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            status,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(status),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: _getStatusColor(status),
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getStatusText(status),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'تاريخ الطلب: $dateString',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 2. تفاصيل المركبة والمشكلة
                      const Text(
                        'المعلومات الأساسية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.directions_car_rounded,
                              'المركبة',
                              data['carModel'] ?? 'غير محدد',
                            ),
                            const Divider(color: Colors.white10, height: 30),
                            // 🚀 تم تعديل الحقل من category إلى faultType
                            _buildDetailRow(
                              Icons.category_rounded,
                              'نوع الخدمة',
                              data['faultType'] ?? 'غير محدد',
                            ),
                            const Divider(color: Colors.white10, height: 30),
                            if (data['remotePickup'] == true) ...[
                              _buildDetailRow(
                                Icons.delivery_dining_rounded,
                                'خدمة الاستلام',
                                'استلام من الموقع',
                                iconColor: const Color(0xFFF59E0B),
                              ),
                              const Divider(color: Colors.white10, height: 30),
                            ],
                            // 🚀 تم تعديل الحقل من issueDescription إلى description
                            _buildDetailRow(
                              Icons.handyman_rounded,
                              'تفاصيل العطل',
                              data['description'] ?? 'لا يوجد تفاصيل',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      _CustomerInspectionReport(
                        key: ValueKey('$orderId:$reportId:${user.uid}'),
                        orderId: orderId,
                        decisionsAllowed:
                            [
                              'inspecting',
                              'pending_approval',
                            ].contains(status) &&
                            data['inspectionStatus'] == 'awaitingApproval',
                        reportId: reportId is String && reportId.isNotEmpty
                            ? reportId
                            : null,
                      ),
                      const SizedBox(height: 32),

                      // 3. صورة العطل (إن وجدت)
                      if (data['issueImageUrl'] != null &&
                          data['issueImageUrl'].toString().isNotEmpty) ...[
                        const Text(
                          'صورة العطل المرفقة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            data['issueImageUrl'],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // 4. زر إلغاء الطلب (يظهر فقط إذا كان بانتظار القبول)
                      if (status == 'pending') ...[
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelOrder(context),
                            icon: const Icon(
                              Icons.cancel_rounded,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'إلغاء الطلب',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ويدجت مساعدة لبناء صفوف التفاصيل
  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value, {
    Color iconColor = Colors.white54,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomerInspectionReport extends StatefulWidget {
  final String orderId;
  final bool decisionsAllowed;
  final String? reportId;

  const _CustomerInspectionReport({
    super.key,
    required this.orderId,
    required this.reportId,
    required this.decisionsAllowed,
  });

  @override
  State<_CustomerInspectionReport> createState() =>
      _CustomerInspectionReportState();
}

class _CustomerInspectionReportState extends State<_CustomerInspectionReport> {
  late final Stream<InspectionReport?>? _reportStream;

  final _inspectionService = InspectionService();
  final Set<String> _savingItems = {};
  final Map<String, PartApprovalStatus> _savedDecisions = {};

  Future<void> _decide(InspectionItem item, PartApprovalStatus decision) async {
    final reportId = widget.reportId;
    if (reportId == null ||
        _savingItems.contains(item.id) ||
        _savedDecisions.containsKey(item.id)) {
      return;
    }
    setState(() => _savingItems.add(item.id));
    try {
      await _inspectionService.decideItem(
        orderId: widget.orderId,
        reportId: reportId,
        itemId: item.id,
        decision: decision,
      );
      if (!mounted) {
        return;
      }
      setState(() => _savedDecisions[item.id] = decision);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == PartApprovalStatus.approved
                ? 'تم حفظ موافقتك على الإصلاح.'
                : 'تم حفظ رفض الإصلاح.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is InspectionDecisionException
                  ? error.message
                  : 'تعذر حفظ القرار. تحقق من الاتصال وصلاحيات الوصول وحاول مجدداً.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingItems.remove(item.id));
      }
    }
  }

  Widget _decisionActions(InspectionReport report, InspectionItem item) {
    final saved = _savedDecisions[item.id];
    if (saved != null && item.approvalStatus == PartApprovalStatus.pending) {
      return _message(_approval(saved));
    }
    if (_savingItems.contains(item.id)) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('جارٍ حفظ القرار...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
    if (!widget.decisionsAllowed ||
        report.status != InspectionReportStatus.awaitingApproval ||
        !item.requiresApproval ||
        item.approvalStatus != PartApprovalStatus.pending) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          FilledButton(
            onPressed: () => _decide(item, PartApprovalStatus.approved),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('موافق على الإصلاح'),
          ),
          OutlinedButton(
            onPressed: () => _decide(item, PartApprovalStatus.rejected),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('رفض الإصلاح'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final reportId = widget.reportId;
    _reportStream = reportId == null
        ? null
        : InspectionService().watchReport(
            orderId: widget.orderId,
            reportId: reportId,
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
    PartApprovalStatus.pending => 'بانتظار موافقتك',
    PartApprovalStatus.approved => 'تمت الموافقة على الإصلاح',
    PartApprovalStatus.rejected => 'تم رفض الإصلاح',
    PartApprovalStatus.notRequired => 'لا تتطلب موافقة',
  };

  Widget _message(String message) =>
      Text(message, style: const TextStyle(color: Colors.white70));

  Widget _card(Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF334155).withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
    ),
    child: DefaultTextStyle(
      style: const TextStyle(color: Colors.white70, height: 1.6),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '📋 تقرير الفحص',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      if (_reportStream == null)
        _message('لم يتم إرسال تقرير فحص لهذا الطلب بعد.')
      else
        StreamBuilder<InspectionReport?>(
          stream: _reportStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _message(
                'تعذر تحميل تقرير الفحص. تحقق من الاتصال وصلاحيات الوصول.',
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
              );
            }
            final report = snapshot.data;
            if (report == null) {
              return _message('لم يتم العثور على تقرير الفحص المرتبط بالطلب.');
            }
            if (report.orderId != widget.orderId ||
                report.id != widget.reportId) {
              return _message('بيانات تقرير الفحص لا تطابق هذا الطلب.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.items.isEmpty)
                  _message('لا توجد قطع في تقرير الفحص.'),
                ...report.items.map(
                  (item) => _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _condition(item.condition),
                          style: TextStyle(color: _color(item.condition)),
                        ),
                        Text(
                          'حالة الموافقة: ${_approval(_savedDecisions[item.id] ?? item.approvalStatus)}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ملاحظات الفني: ${item.notes.isEmpty ? 'لا توجد ملاحظات' : item.notes}',
                        ),
                        if (item.imageUrl != null &&
                            item.imageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.imageUrl!,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _message('تعذر عرض صورة القطعة.'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'سعر القطعة: ${item.partPrice.toStringAsFixed(2)} د.أ',
                        ),
                        Text(
                          'أجرة العمل: ${item.laborCost.toStringAsFixed(2)} د.أ',
                        ),
                        Text(
                          'المجموع: ${item.totalCost.toStringAsFixed(2)} د.أ',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _decisionActions(report, item),
                      ],
                    ),
                  ),
                ),
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجمالي التكلفة التقديرية: ${report.totalEstimatedCost.toStringAsFixed(2)} د.أ',
                      ),
                      Text(
                        'إجمالي الإصلاحات الموافق عليها: ${report.totalApprovedCost.toStringAsFixed(2)} د.أ',
                      ),
                      if (report.status == InspectionReportStatus.reviewed &&
                          !report.items.any(
                            (item) =>
                                item.requiresApproval &&
                                item.approvalStatus ==
                                    PartApprovalStatus.approved,
                          ))
                        const Text(
                          'لا توجد إصلاحات وافق عليها الزبون؛ لا تُنفذ إصلاحات لهذا التقرير.',
                        ),
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
    ],
  );
}
