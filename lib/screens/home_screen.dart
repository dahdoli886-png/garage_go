import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'add_order_screen.dart';
import 'role_selection_screen.dart'; // تأكد من مسار صفحة الترحيب
import 'profile_screen.dart'; // تأكد من مسار صفحة الملف الشخصي
import 'my_vehicles_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart'; // تأكد من مسار صفحة الدعم الفني
import 'order_details_screen.dart'; // ضيف هاد فوق مع الباقي

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _currentIndex = 0; // للتحكم بـ Bottom Navigation Bar

  // متغيرات اختيار الموقع
  String _selectedLocation = 'إربد, الأردن';
  final List<String> _availableLocations = [
    'إربد, الأردن',
    'عمان, الأردن',
    'الزرقاء, الأردن',
    'المفرق, الأردن',
    'جرش, الأردن',
  ];

  // دالة تسجيل الخروج
  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    if (mounted) {
      // 🚀 الحل: ارجع لشاشة الترحيب بدل اللوجن مباشرة
      // هيك الـ Stack بصير فيه Welcome -> Login، فالسهم بشتغل طبيعي!
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  // دالة إظهار قائمة المواقع السفلية
  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D3E53),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر موقعك الحالي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._availableLocations.map(
                (location) => ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Color(0xFFF39C12),
                  ),
                  title: Text(
                    location,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  trailing: _selectedLocation == location
                      ? const Icon(Icons.check_circle, color: Color(0xFFF39C12))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLocation = location;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // دوال مساعدة لحالة الطلبات
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
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
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'بانتظار القبول';
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
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF243141),

      //=========================================
      // 1. شريط التنقل العلوي (AppBar)
      //=========================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D3E53),
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: _showLocationPicker,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'الموقع الحالي',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFFF39C12),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedLocation,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      //=========================================
      // 2. القائمة الجانبية (App Drawer)
      //=========================================
      drawer: Drawer(
        backgroundColor: const Color(0xFF2D3E53),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF243141)),
              child: currentUser == null
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Color(0xFFF39C12),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'أهلاً بك، عميلنا العزيز',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser!.uid)
                          .get(),
                      builder: (context, snapshot) {
                        String displayName = 'عميلنا العزيز';
                        String profileImgUrl = '';

                        if (snapshot.hasData && snapshot.data!.data() != null) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          displayName = data['name'] ?? 'عميلنا العزيز';
                          profileImgUrl =
                              data['profileImageUrl'] ??
                              ''; // قراءة الرابط من الداتابيز
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: const Color(0xFFF39C12),
                              // فحص إذا كان الرابط غير فارغ يعرض الصورة من الإنترنت
                              backgroundImage: profileImgUrl.isNotEmpty
                                  ? NetworkImage(profileImgUrl)
                                  : null,
                              child: profileImgUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'أهلاً بك، $displayName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'ملفي الشخصي',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),
            _buildDrawerItem(
              icon: Icons.directions_car_filled_outlined,
              title: 'مركباتي',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
            ),
            _buildDrawerItem(
              icon: Icons.history_rounded,
              title: 'طلباتي',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            const Divider(color: Colors.white10, thickness: 1),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'الإعدادات',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.support_agent_rounded,
              title: 'الدعم الفني',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportScreen(),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white10, thickness: 1),
            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'تسجيل الخروج',
              color: Colors.redAccent,
              onTap: _logout,
            ),
          ],
        ),
      ),

      //=========================================
      // 3. محتوى الصفحة حسب التاب المختار
      //=========================================
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeContent(), // 0: الرئيسية
            _buildOrdersContent(), // 1: طلباتي 🚀 تم إرجاعها للدالة الصحيحة
            const ProfileScreen(), // 2: حسابي الشخصي
            const MyVehiclesScreen(), // 3: مركباتي
          ],
        ),
      ),

      //=========================================
      // 4. شريط التنقل السفلي (Bottom Navigation Bar)
      //=========================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF2D3E53),
          selectedItemColor: const Color(0xFFF39C12),
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'طلباتي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_rounded),
              label: 'مركباتي',
            ),
          ],
        ),
      ),
    );
  }

  // 1. واجهة الرئيسية (Home)
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMainActionCard(
                  title: 'طلب جديد',
                  subtitle: 'إنشاء طلب صيانة',
                  icon: Icons.add_circle_outline_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddOrderScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMainActionCard(
                  title: 'طلباتي',
                  subtitle: 'متابعة طلباتك',
                  icon: Icons.receipt_long_rounded,
                  onTap: () {
                    setState(() => _currentIndex = 1);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 🚀 القسم التفاعلي للمركبات اللي ضفناه 🚀
          _buildMyVehiclesSection(),

          const SizedBox(height: 32),

          const Text(
            'الخدمات السريعة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildServiceIcon(
                title: 'ميكانيك',
                icon: Icons.build_circle_outlined,
              ),
              _buildServiceIcon(
                title: 'كهرباء',
                icon: Icons.electrical_services_rounded,
              ),
              _buildServiceIcon(
                title: 'ونش إنقاذ',
                icon: Icons.car_crash_outlined,
              ),
              _buildServiceIcon(
                title: 'إطارات',
                icon: Icons.tire_repair_outlined,
              ),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ورشات قريبة منك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(color: Color(0xFFF39C12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildNearbyWorkshopCard(
            name: 'كراج الأمانة للميكانيك',
            distance: '1.2 كم',
            rating: '4.8',
          ),
          const SizedBox(height: 12),
          _buildNearbyWorkshopCard(
            name: 'المركز الفني لفحص السيارات',
            distance: '3.5 كم',
            rating: '4.5',
          ),
        ],
      ),
    );
  }

  // 🚀 دالة بناء قسم مركباتي التفاعلي 🚀
  Widget _buildMyVehiclesSection() {
    if (currentUser == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مركباتي',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90, // ارتفاع كرت السيارة
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .collection('vehicles')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF39C12)),
                );
              }

              // إذا ما في سيارات مضافة (Empty State)
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return GestureDetector(
                  onTap: () {
                    // الانتقال لتاب المركبات
                    setState(() => _currentIndex = 3);
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3E53).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF39C12).withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: Color(0xFFF39C12),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'أضف مركبتك الأولى',
                          style: TextStyle(
                            color: Color(0xFFF39C12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final vehicles = snapshot.data!.docs;

              // عرض السيارات بشكل أفقي (Horizontal ListView)
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle =
                      vehicles[index].data() as Map<String, dynamic>;
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3E53),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF39C12).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            color: Color(0xFFF39C12),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${vehicle['brand']} ${vehicle['model']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${vehicle['plateNumber']}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 2. واجهة طلباتي (من الفايربيس)
  // 2. واجهة طلباتي (قراءة مباشرة من الكولكشن الرئيسي)
  Widget _buildOrdersContent() {
    if (currentUser == null) return const SizedBox();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'طلباتي السابقة والحالية',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // 🚀 التعديل هنا: صرنا نقرأ مباشرة من نفس المكان اللي حفظنا فيه
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF39C12)),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'صار خطأ: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.car_repair, size: 80, color: Colors.white24),
                      SizedBox(height: 16),
                      Text(
                        'ما في طلبات بعد',
                        style: TextStyle(fontSize: 18, color: Colors.white54),
                      ),
                    ],
                  ),
                );
              }

              // ترتيب الطلبات من الأحدث للأقدم برمجياً
              // (عشان نتجنب مشكلة الـ Index في فايربيس)
              final orders = snapshot.data!.docs.toList();
              orders.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final data = orders[index].data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderDetailsScreen(orderId: orders[index].id),
                        ),
                      );
                    },
                    child: Card(
                      color: const Color(0xFF2D3E53),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.directions_car,
                                      color: Color(0xFFF39C12),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      data['carModel'] ?? 'سيارة',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      status,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                                  child: Text(
                                    _getStatusText(status),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data['issueDescription'] ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (data['remotePickup'] == true) ...[
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.delivery_dining,
                                    size: 16,
                                    color: Color(0xFFF39C12),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'استلام من الموقع',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFF39C12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 3. واجهة حسابي الشخصي
  Widget _buildProfileContent() {
    if (currentUser == null) {
      return const Center(
        child: Text(
          'لم يتم تسجيل الدخول',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get(),
        builder: (context, snapshot) {
          String displayName = currentUser?.email ?? 'مستخدم';
          String profileImgUrl = '';

          if (snapshot.hasData && snapshot.data!.data() != null) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            displayName = data['name'] ?? currentUser?.email ?? 'مستخدم';
            profileImgUrl = data['profileImageUrl'] ?? ''; // قراءة رابط الصورة
          }

          return Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFF39C12),
                backgroundImage: profileImgUrl.isNotEmpty
                    ? NetworkImage(profileImgUrl)
                    : null,
                child: profileImgUrl.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'حسابي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(displayName, style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 40),
              ListTile(
                tileColor: const Color(0xFF2D3E53),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: _logout,
              ),
            ],
          );
        },
      ),
    );
  }

  // دوال بناء المكونات الصغيرة
  Widget _buildMainActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D3E53),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF39C12).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF39C12).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFF39C12), size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white70, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  Widget _buildServiceIcon({required String title, required IconData icon}) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF2D3E53),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: Icon(icon, color: const Color(0xFFF39C12), size: 32),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildNearbyWorkshopCard({
    required String name,
    required String distance,
    required String rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3E53),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF243141),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.store_mall_directory_rounded,
              color: Colors.white54,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
