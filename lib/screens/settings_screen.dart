import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_selection_screen.dart'; // مسار شاشة البداية بعد حذف الحساب

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  // دالة لحذف الحساب (مطلوبة جداً في سياسات جوجل وأبل)
  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3E53),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('حذف الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من أنك تريد حذف حسابك نهائياً؟ سيتم مسح جميع بياناتك وطلباتك ولن تتمكن من التراجع عن هذا الإجراء.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context); // إغلاق النافذة
              try {
                // عرض مؤشر تحميل
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
                );

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // حذف بيانات المستخدم من Firestore
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                  // حذف الحساب من Authentication
                  await user.delete();
                }

                if (mounted) {
                  Navigator.pop(context); // إغلاق مؤشر التحميل
                  // التوجه لشاشة البداية وتنظيف الـ Stack
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الحساب بنجاح'), backgroundColor: Colors.redAccent),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // إغلاق مؤشر التحميل
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: قد تحتاج لتسجيل الدخول مجدداً قبل الحذف. ($e)'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('نعم، احذف حسابي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF243141),
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم تفضيلات التطبيق
            _buildSectionTitle('تفضيلات التطبيق'),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D3E53),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'الإشعارات',
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                  ),
                  const Divider(color: Colors.white10, height: 1, indent: 60, endIndent: 20),
                  _buildNavigationTile(
                    icon: Icons.language_rounded,
                    title: 'لغة التطبيق',
                    trailingText: 'العربية',
                    onTap: () {
                      // هنا تفتح نافذة تغيير اللغة
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // قسم الدعم والمساعدة
            _buildSectionTitle('الدعم والمساعدة'),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D3E53),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildNavigationTile(
                    icon: Icons.support_agent_rounded,
                    title: 'تواصل معنا',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10, height: 1, indent: 60, endIndent: 20),
                  _buildNavigationTile(
                    icon: Icons.description_outlined,
                    title: 'الشروط والأحكام',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10, height: 1, indent: 60, endIndent: 20),
                  _buildNavigationTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'سياسة الخصوصية',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // قسم الحساب (منطقة الخطر)
            _buildSectionTitle('الحساب'),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D3E53),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                ),
                title: const Text('حذف الحساب نهائياً', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                onTap: _deleteAccount,
              ),
            ),
            const SizedBox(height: 40),
            
            // إصدار التطبيق
            const Center(
              child: Text(
                'GarageGo v1.0.0',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── دوال بناء المكونات (Widgets) ───

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF39C12).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFF39C12)),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(trailingText, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF39C12).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFF39C12)),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFF39C12),
        activeTrackColor: const Color(0xFFF39C12).withValues(alpha: 0.5),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.white10,
      ),
    );
  }
}