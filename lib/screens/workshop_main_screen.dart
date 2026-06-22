import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workshop_home_screen.dart';

// ─── الألوان ─────────────────────────────────────────────────────────────
const _kBg = Color(0xFF070D18);
const _kSurface = Color(0xFF0D1B2A);
const _kBorder = Color(0xFF1E3A5F);
const _kOrange = Color(0xFFFF6B35);
const _kGold = Color(0xFFF5A623);
const _kTextPri = Color(0xFFE8EDF5);
const _kTextSec = Color(0xFF94A3B8);
const _kTextMuted = Color(0xFF475569);

class WorkshopMainScreen extends StatefulWidget {
  const WorkshopMainScreen({super.key});

  @override
  State<WorkshopMainScreen> createState() => _WorkshopMainScreenState();
}

class _WorkshopMainScreenState extends State<WorkshopMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const WorkshopHomeScreen(),
    const _PlaceholderScreen(icon: '🕐', title: 'سجل الصيانة', subtitle: 'سيتوفر قريباً'),
    const _PlaceholderScreen(icon: '👤', title: 'حساب الورشة', subtitle: 'سيتوفر قريباً'),
    const _PlaceholderScreen(icon: '📊', title: 'الإحصائيات', subtitle: 'سيتوفر قريباً'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(context),
        drawer: _buildDrawer(context),
        body: _screens[_currentIndex],
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ─── AppBar ديناميكي ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    String title = '';
    switch (_currentIndex) {
      case 0: title = 'لوحة تحكم الورشة'; break;
      case 1: title = 'سجل الصيانة'; break;
      case 2: title = 'حساب الورشة'; break;
      case 3: title = 'الإحصائيات'; break;
    }

    return AppBar(
      backgroundColor: _kSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Container(
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.menu_rounded, color: _kTextSec, size: 22),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentIndex == 0) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kOrange, _kGold], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: _kOrange.withOpacity(0.5), blurRadius: 12)],
              ),
              child: const Icon(Icons.build_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(color: _kTextPri, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              if (_currentIndex == 0)
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.6), blurRadius: 6)]),
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
        child: Container(height: 1, color: _kBorder),
      ),
    );
  }

  // ─── Bottom Navigation Bar ────────────────────────────────────────────────
  Widget _buildBottomNav() {
    // 🚀 التعديل هنا: إضافة لون مخصص لكل زر
    final items = [
      const _NavItem(icon: Icons.inbox_rounded, label: 'الطلبات', activeColor: _kOrange),
      const _NavItem(icon: Icons.history_rounded, label: 'السجل', activeColor: Color(0xFF3B82F6)),
      const _NavItem(icon: Icons.storefront_rounded, label: 'حسابي', activeColor: Color(0xFF8B5CF6)), // لون بنفسجي للحساب
      const _NavItem(icon: Icons.analytics_rounded, label: 'الاحصائيات', activeColor: Color(0xFF10B981)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        border: const Border(top: BorderSide(color: _kBorder, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = _currentIndex == i;
              final activeColor = items[i].activeColor; // 🚀 قراءة اللون من القائمة
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: isActive
                        ? BoxDecoration(
                            color: activeColor.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(14), 
                            border: Border.all(color: activeColor.withOpacity(0.3)))
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i].icon, size: isActive ? 26 : 22, color: isActive ? activeColor : _kTextMuted),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: isActive ? activeColor : _kTextMuted),
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 4),
                          Container(width: 4, height: 4, decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ─── Drawer ───────────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: _kSurface,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              color: _kBg,
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kOrange, _kGold]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: _kOrange.withOpacity(0.4), blurRadius: 16)],
                    ),
                    child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 14),
                  const Text('لوحة تحكم الورشة', style: TextStyle(color: _kTextPri, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('مرحباً بك 👋', style: TextStyle(color: _kTextMuted, fontSize: 12)),
                ],
              ),
            ),
            Container(height: 1, color: _kBorder),
            const SizedBox(height: 8),
            _drawerItem(
              icon: Icons.dashboard_rounded, label: 'لوحة التحكم', color: _kOrange, isActive: _currentIndex == 0,
              onTap: () { setState(() => _currentIndex = 0); Navigator.pop(context); },
            ),
            _drawerItem(
              icon: Icons.history_rounded, label: 'سجل الطلبات', color: const Color(0xFF3B82F6), isActive: _currentIndex == 1,
              onTap: () { setState(() => _currentIndex = 1); Navigator.pop(context); },
            ),
            // 🚀 التعديل هنا: إضافة زر حساب الورشة لتطابق الشريط السفلي
            _drawerItem(
              icon: Icons.storefront_rounded, label: 'حساب الورشة', color: const Color(0xFF8B5CF6), isActive: _currentIndex == 2,
              onTap: () { setState(() => _currentIndex = 2); Navigator.pop(context); },
            ),
            _drawerItem(
              icon: Icons.bar_chart_rounded, label: 'الإحصائيات', color: const Color(0xFF10B981), isActive: _currentIndex == 3,
              onTap: () { setState(() => _currentIndex = 3); Navigator.pop(context); },
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Container(height: 1, color: _kBorder)),
            _drawerItem(
              icon: Icons.logout_rounded, label: 'تسجيل الخروج', color: const Color(0xFFEF4444),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String label, required Color color, required VoidCallback onTap, bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? color.withOpacity(0.08) : Colors.transparent,
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: TextStyle(color: isActive ? color : _kTextPri, fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
        trailing: isActive ? Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)) : null,
      ),
    );
  }
}

// ─── شاشة placeholder مؤقتة ──────────────────────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  const _PlaceholderScreen({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: _kTextPri, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: _kTextMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

// 🚀 التعديل هنا: إضافة خاصية activeColor للكلاس
class _NavItem {
  final IconData icon;
  final String label;
  final Color activeColor;
  const _NavItem({required this.icon, required this.label, required this.activeColor});
}