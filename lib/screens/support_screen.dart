import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  // ─── دوال التواصل الخارجي (url_launcher) ───
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح الرابط، تأكد من وجود التطبيق المناسب.')),
        );
      }
    }
  }

  // ─── إرسال تذكرة دعم للفايربيس ───
  Future<void> _submitTicket() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة رسالتك أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user?.uid ?? 'guest',
        'email': user?.email ?? 'غير متوفر',
        'message': _messageController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رسالتك بنجاح، سنتواصل معك قريباً ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الإرسال: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF243141),
      appBar: AppBar(
        title: const Text('الدعم الفني', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة أو أيقونة ترحيبية
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFF39C12).withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.support_agent_rounded, size: 60, color: Color(0xFFF39C12)),
                  ),
                  const SizedBox(height: 16),
                  const Text('كيف يمكننا مساعدتك اليوم؟', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('فريقنا متواجد للرد على استفساراتك وحل أي مشكلة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 1. طرق التواصل السريعة
            const Text('تواصل معنا مباشرة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildContactCard(icon: Icons.chat_rounded, title: 'واتساب', color: Colors.green, onTap: () => _launchURL('https://wa.me/+962775685457'))), // حط رقمك هون
                const SizedBox(width: 12),
                Expanded(child: _buildContactCard(icon: Icons.phone_rounded, title: 'اتصال', color: Colors.blueAccent, onTap: () => _launchURL('tel:+962775685457'))),
                const SizedBox(width: 12),
                Expanded(child: _buildContactCard(icon: Icons.email_rounded, title: 'إيميل', color: Colors.redAccent, onTap: () => _launchURL('mailto:support@garagego.com'))),
              ],
            ),
            const SizedBox(height: 40),

            // 2. إرسال رسالة من التطبيق
            const Text('أو أرسل لنا رسالة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF2D3E53), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب مشكلتك أو استفسارك هنا...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF243141),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _submitTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF39C12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isSending 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('إرسال الرسالة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 3. الأسئلة الشائعة (FAQ)
            const Text('الأسئلة الشائعة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFAQTile('كيف يمكنني حجز موعد صيانة؟', 'يمكنك حجز موعد من خلال الشاشة الرئيسية بالضغط على "طلب جديد" وتعبئة بيانات مركبتك ونوع العطل.'),
            _buildFAQTile('كيف يتم تحديد تكلفة الإصلاح؟', 'بعد استلام الورشة لطلبك أو فحص سيارتك، سيقوم الفني بإرسال تسعيرة مبدئية لك عبر التطبيق لتوافق عليها قبل بدء العمل.'),
            _buildFAQTile('هل يمكنني إلغاء الطلب؟', 'نعم، يمكنك إلغاء الطلب طالما أن حالته "بانتظار القبول" ولم يتم تعيين سائق أو بدء العمل به.'),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // كرت طرق التواصل المربع
  Widget _buildContactCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFF2D3E53), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // تصميم سؤال وجواب
  Widget _buildFAQTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3E53),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // لإخفاء الخطوط الافتراضية
        child: ExpansionTile(
          iconColor: const Color(0xFFF39C12),
          collapsedIconColor: Colors.white54,
          title: Text(question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(answer, style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}