import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  bool _isUploadingImage = false;

  // دالة لتغيير الصورة الشخصية ورفعها لـ Cloudinary
  Future<void> _pickAndUploadImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        File imageFile = File(pickedFile.path);
        String newImageUrl = await _authService.uploadImage(imageFile, 'customer_profiles', user!.uid);
        await _authService.updateUserData(user!.uid, {'profileImageUrl': newImageUrl});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث الصورة بنجاح ✅', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green,
            )
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الرفع: $e'),
              backgroundColor: Colors.redAccent,
            )
          );
        }
      } finally {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  // دالة فتح نافذة التعديل مع SnackBar للنجاح والفشل
  void _showEditDialog(String fieldName, String currentValue, String firestoreKey) {
    final controller = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D3E53),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تعديل $fieldName', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF243141),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFF39C12), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF39C12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    try {
                      await _authService.updateUserData(user!.uid, {firestoreKey: controller.text.trim()});
                      if (mounted) {
                        Navigator.pop(context); // إغلاق النافذة بعد النجاح
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم تحديث $fieldName بنجاح ✅', style: const TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // إغلاق النافذة في حال الخطأ
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('حدث خطأ أثناء التحديث، حاول مجدداً ❌', style: TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('حفظ التعديلات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF243141),
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFF39C12)));
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          
          String profileImageUrl = data['profileImageUrl'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.5), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: const Color(0xFF2D3E53),
                            backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                            child: profileImageUrl.isEmpty 
                                ? const Icon(Icons.person, size: 50, color: Colors.white54) 
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF39C12),
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingImage 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                const Text('المعلومات الشخصية', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                _buildPremiumEditableField(
                  icon: Icons.person_outline,
                  label: 'الاسم الكامل',
                  value: data['name'] ?? 'غير متوفر',
                  isEditable: true,
                  onEdit: () => _showEditDialog('الاسم', data['name'] ?? '', 'name'),
                ),
                
                _buildPremiumEditableField(
                  icon: Icons.email_outlined,
                  label: 'البريد الإلكتروني',
                  value: user?.email ?? 'غير متوفر',
                  isEditable: false,
                ),

                _buildPremiumEditableField(
                  icon: Icons.phone_outlined,
                  label: 'رقم الهاتف',
                  value: data['phone'] ?? 'غير متوفر',
                  isEditable: true,
                  onEdit: () => _showEditDialog('رقم الهاتف', data['phone'] ?? '', 'phone'),
                ),

                const SizedBox(height: 32),

                const Text('الأمان', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3E53),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFF39C12).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFF39C12)),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: Text('تغيير كلمة المرور', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumEditableField({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditable,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3E53),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF39C12).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFF39C12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white54),
              onPressed: onEdit,
              splashRadius: 24,
            )
          else
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 20),
            ),
        ],
      ),
    );
  }
}