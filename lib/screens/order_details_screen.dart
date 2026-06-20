import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

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
        return 'جاهز للتسليم';
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
    return Scaffold(
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
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
          final status = data['status'] ?? 'pending';
          final createdAt = data['createdAt'] as Timestamp?;
          final dateString = createdAt != null
              ? DateFormat('yyyy-MM-dd / hh:mm a').format(createdAt.toDate())
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
                    color: _getStatusColor(status).withOpacity(0.15),
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
                    color: const Color(0xFF334155).withOpacity(0.4),
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
