import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── نموذج بيانات الطلب ──────────────────────────────────────────────────────
class OrderModel {
  final String id;
  final String faultType;
  final String customerName;
  final String carBrand;
  final String carModel;
  final String description;
  final String status;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.faultType,
    required this.customerName,
    required this.carBrand,
    required this.carModel,
    required this.description,
    required this.status,
    this.createdAt,
  });

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      faultType: d['faultType'] ?? 'غير محدد',
      customerName: d['customerName'] ?? 'مجهول',
      carBrand: d['carBrand'] ?? '',
      carModel: d['carModel'] ?? '',
      description: d['description'] ?? '',
      status: d['status'] ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ─── إعدادات الحالات ─────────────────────────────────────────────────────────
class StatusConfig {
  final String label;
  final Color color;
  final IconData icon;
  final String emoji;

  const StatusConfig({
    required this.label,
    required this.color,
    required this.icon,
    required this.emoji,
  });
}

final Map<String, StatusConfig> kStatusConfig = {
  'pending':    StatusConfig(label: 'طلب جديد',       color: Color(0xFFFF6B35), icon: Icons.notifications_rounded,    emoji: '🔔'),
  'accepted':   StatusConfig(label: 'مقبول',           color: Color(0xFF3B82F6), icon: Icons.check_circle_rounded,     emoji: '✅'),
  'inspecting': StatusConfig(label: 'جاري الفحص',     color: Color(0xFF8B5CF6), icon: Icons.search_rounded,           emoji: '🔍'),
  'fixing':     StatusConfig(label: 'تحت الصيانة',    color: Color(0xFF06B6D4), icon: Icons.build_circle_rounded,     emoji: '🔧'),
  'ready':      StatusConfig(label: 'جاهز للتسليم',   color: Color(0xFF10B981), icon: Icons.star_rounded,             emoji: '✨'),
  'completed':  StatusConfig(label: 'مكتمل',          color: Color(0xFF6B7280), icon: Icons.flag_rounded,             emoji: '🏁'),
  'refused':    StatusConfig(label: 'مرفوض',          color: Color(0xFFEF4444), icon: Icons.cancel_rounded,           emoji: '❌'),
  'cancelled':  StatusConfig(label: 'ملغي',           color: Color(0xFFEF4444), icon: Icons.cancel_outlined,          emoji: '🚫'),
};

// ─── الألوان الرئيسية ─────────────────────────────────────────────────────────
const kBg        = Color(0xFF070D18);
const kSurface   = Color(0xFF0D1B2A);
const kSurface2  = Color(0xFF0F2236);
const kBorder    = Color(0xFF1E3A5F);
const kOrange    = Color(0xFFFF6B35);
const kGold      = Color(0xFFF5A623);
const kTextPri   = Color(0xFFE8EDF5);
const kTextSec   = Color(0xFF94A3B8);
const kTextMuted = Color(0xFF475569);

// ─── الشاشة الرئيسية ─────────────────────────────────────────────────────────
class WorkshopHomeScreen extends StatefulWidget {
  const WorkshopHomeScreen({super.key});

  @override
  State<WorkshopHomeScreen> createState() => _WorkshopHomeScreenState();
}

class _WorkshopHomeScreenState extends State<WorkshopHomeScreen>
    with SingleTickerProviderStateMixin {
  final User? _user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── تحديث حالة الطلب ────────────────────────────────────────────────────
  Future<void> _updateStatus(String orderId, String newStatus,
      {bool isFirstAccept = false}) async {
    try {
      final Map<String, dynamic> data = {'status': newStatus};
      if (isFirstAccept) data['workshopId'] = _user!.uid;

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update(data);

      if (!mounted) return;
      final isAccept = newStatus == 'accepted';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: isAccept ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            isAccept ? '✅ تم استلام الطلب بنجاح' : '❌ تم رفض الطلب',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ─── بناء الشاشة ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,
        // ─ AppBar ثابت وواضح ─
        appBar: _buildAppBar(context),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('workshopId', whereIn: ['all', _user?.uid])
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            List<OrderModel> pending = [];
            List<OrderModel> active = [];

            if (snap.hasData) {
              for (final doc in snap.data!.docs) {
                final order = OrderModel.fromDoc(doc);
                final data = doc.data() as Map<String, dynamic>;

                if (order.status == 'pending' && data['workshopId'] == 'all') {
                  pending.add(order);
                } else if (data['workshopId'] == _user?.uid &&
                    !['pending', 'refused', 'completed', 'cancelled']
                        .contains(order.status)) {
                  active.add(order);
                }
              }
            }

            return Column(
              children: [
                // ─ شريط الإحصائيات + التابات ─
                _buildSubHeader(pending.length, active.length),
                // ─ المحتوى ─
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(pending, isPending: true),
                      _buildList(active, isPending: false),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── AppBar الرئيسي ──────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: const Icon(Icons.menu_rounded, color: kTextSec, size: 22),
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kOrange, kGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: kOrange.withOpacity(0.5), blurRadius: 12)],
            ),
            child: const Icon(Icons.build_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'لوحة تحكم الورشة',
                style: TextStyle(color: kTextPri, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.6), blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('متصل ونشط', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: kBorder),
      ),
    );
  }

  // ─── شريط الإحصائيات والتابات ────────────────────────────────────────────
  Widget _buildSubHeader(int pendingCount, int activeCount) {
    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // الإحصائيات
          Row(
            children: [
              _buildStatCard('🔔', pendingCount.toString(), 'طلبات جديدة', kOrange),
              const SizedBox(width: 8),
              _buildStatCard('⚙️', activeCount.toString(), 'قيد العمل', const Color(0xFF06B6D4)),
              const SizedBox(width: 8),
              _buildStatCard('✅', '0', 'مكتملة اليوم', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 12),
          // تابات
          Container(
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: const LinearGradient(colors: [kOrange, kGold]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: kOrange.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: kTextMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🆕 طلبات جديدة'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: _tabController.index == 0
                                ? Colors.white.withOpacity(0.25)
                                : kOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _tabController.index == 0 ? Colors.white : kOrange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚙️ ورشة العمل'),
                      if (activeCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: _tabController.index == 1
                                ? Colors.white.withOpacity(0.25)
                                : kOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$activeCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _tabController.index == 1 ? Colors.white : kOrange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: kTextMuted, fontSize: 9), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── قائمة الطلبات ────────────────────────────────────────────────────────
  Widget _buildList(List<OrderModel> orders, {required bool isPending}) {
    if (orders.isEmpty) {
      return _buildEmptyState(
        isPending ? '📭' : '🏭',
        isPending ? 'لا يوجد طلبات جديدة' : 'لا يوجد سيارات قيد العمل',
        isPending ? 'ستظهر الطلبات الواردة هنا فور وصولها' : 'اقبل طلباً جديداً لبدء العمل',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: orders.length,
      itemBuilder: (ctx, i) => _buildOrderCard(orders[i], isPending),
    );
  }

  // ─── بطاقة الطلب ─────────────────────────────────────────────────────────
  Widget _buildOrderCard(OrderModel order, bool isPending) {
    final cfg = kStatusConfig[order.status] ?? kStatusConfig['pending']!;
    final timeAgo = _timeAgo(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kSurface, kSurface2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: cfg.color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ الهيدر ─
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.faultType,
                        style: const TextStyle(color: kTextPri, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(timeAgo, style: const TextStyle(color: kTextMuted, fontSize: 11)),
                    ],
                  ),
                ),
                _buildStatusBadge(cfg),
              ],
            ),

            // ─ فاصل ─
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, kBorder, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ─ معلومات ─
            Row(
              children: [
                Expanded(child: _buildInfoCell('👤', 'العميل', order.customerName)),
                const SizedBox(width: 10),
                Expanded(child: _buildInfoCell('🚗', 'المركبة', '${order.carBrand} ${order.carModel}')),
              ],
            ),
            const SizedBox(height: 10),
            _buildDescriptionBox(order.description),

            // ─ شريط التقدم (للسيارات النشطة) ─
            if (!isPending && order.status != 'completed') ...[
              const SizedBox(height: 16),
              _buildProgressBar(order.status),
            ],

            // ─ الأزرار ─
            const SizedBox(height: 16),
            if (isPending)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildButton(
                      label: '✅ قبول واستلام',
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      shadow: const Color(0xFF10B981),
                      onTap: () => _updateStatus(order.id, 'accepted', isFirstAccept: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _buildOutlineButton(
                      label: '✕ رفض',
                      color: const Color(0xFFEF4444),
                      onTap: () => _updateStatus(order.id, 'refused'),
                    ),
                  ),
                ],
              )
            else
              _buildManageButton(order, cfg),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(StatusConfig cfg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cfg.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(cfg.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(cfg.label, style: TextStyle(color: cfg.color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildInfoCell(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji $label', style: const TextStyle(color: kTextMuted, fontSize: 10)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: kTextSec, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDescriptionBox(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 تفاصيل الطلب', style: TextStyle(color: kTextMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: kTextSec, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String status) {
    final steps = [
      {'key': 'accepted',   'label': 'استلام', 'emoji': '📥'},
      {'key': 'inspecting', 'label': 'فحص',    'emoji': '🔍'},
      {'key': 'fixing',     'label': 'صيانة',  'emoji': '🔧'},
      {'key': 'ready',      'label': 'جاهز',   'emoji': '✨'},
      {'key': 'completed',  'label': 'تسليم',  'emoji': '🏁'},
    ];
    final currentIdx = steps.indexWhere((s) => s['key'] == status);

    return Column(
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // خط الوصل
              final lineIdx = i ~/ 2;
              final isActive = lineIdx < currentIdx;
              return Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)])
                        : null,
                    color: isActive ? null : kBorder,
                  ),
                ),
              );
            }
            // دائرة
            final stepIdx = i ~/ 2;
            final isActive = stepIdx <= currentIdx;
            final isCurrent = stepIdx == currentIdx;
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent ? kOrange : (isActive ? const Color(0xFF1E3A5F) : const Color(0xFF07111D)),
                border: Border.all(
                  color: isCurrent ? kOrange : (isActive ? const Color(0xFF3B82F6) : kBorder),
                  width: 2,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: kOrange.withOpacity(0.5), blurRadius: 12)]
                    : null,
              ),
              child: Center(
                child: Text(steps[stepIdx]['emoji']!, style: const TextStyle(fontSize: 13)),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((s) {
            final stepIdx = steps.indexOf(s);
            final isActive = stepIdx <= currentIdx;
            return SizedBox(
              width: 32,
              child: Text(
                s['label']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: isActive ? kTextSec : kBorder,
                  fontWeight: stepIdx == currentIdx ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required Gradient gradient,
    required Color shadow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: shadow.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildManageButton(OrderModel order, StatusConfig cfg) {
    return GestureDetector(
      onTap: () => _showManageSheet(order),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cfg.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cfg.color.withOpacity(0.5), width: 1.5),
          boxShadow: [BoxShadow(color: cfg.color.withOpacity(0.15), blurRadius: 16)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_suggest_rounded, color: cfg.color, size: 20),
            const SizedBox(width: 8),
            Text('⚡ إدارة حالة الصيانة', style: TextStyle(color: cfg.color, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Sheet إدارة الطلب ─────────────────────────────────────────────
  void _showManageSheet(OrderModel order) {
    final options = [
      {'key': 'inspecting', 'label': 'جاري الفحص',   'emoji': '🔍'},
      {'key': 'fixing',     'label': 'تحت الصيانة',  'emoji': '🔧'},
      {'key': 'ready',      'label': 'جاهز للتسليم', 'emoji': '✨'},
      {'key': 'completed',  'label': 'تم التسليم',   'emoji': '🏁'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1B2A), Color(0xFF1A2744)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: kBorder),
              left: BorderSide(color: kBorder),
              right: BorderSide(color: kBorder),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 22),
              const Text('🛠 تحديث حالة الصيانة', style: TextStyle(color: kTextPri, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('سيتم إشعار العميل فور التحديث', style: TextStyle(color: kTextMuted, fontSize: 13)),
              const SizedBox(height: 20),

              ...options.map((opt) {
                final cfg = kStatusConfig[opt['key']] ?? kStatusConfig['pending']!;
                final isActive = order.status == opt['key'];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (!isActive) _updateStatus(order.id, opt['key']!);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isActive ? cfg.color.withOpacity(0.1) : const Color(0xFF07111D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isActive ? cfg.color : kBorder, width: isActive ? 1.5 : 1),
                      boxShadow: isActive ? [BoxShadow(color: cfg.color.withOpacity(0.2), blurRadius: 16)] : null,
                    ),
                    child: Row(
                      children: [
                        Text(opt['emoji']!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Text(
                          opt['label']!,
                          style: TextStyle(
                            color: isActive ? cfg.color : kTextSec,
                            fontSize: 15,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (isActive)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: cfg.color, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: cfg.color.withOpacity(0.5), blurRadius: 8)]),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── حالة فارغة ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(String emoji, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: kTextPri, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: kTextMuted, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─── حساب الوقت ──────────────────────────────────────────────────────────
  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24)   return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}