import 'dart:io'; // ضروري للتعامل مع ملفات الصور
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // مكتبة اختيار الصور
import '../services/auth_service.dart';
import 'workshop_login_screen.dart';

class WorkshopRegisterScreen extends StatefulWidget {
  const WorkshopRegisterScreen({super.key});

  @override
  State<WorkshopRegisterScreen> createState() => _WorkshopRegisterScreenState();
}

class _WorkshopRegisterScreenState extends State<WorkshopRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  // ممسكات النصوص
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // متغيرات لحفظ الصور المختارة
  File? _licenseImage;
  File? _shopImage;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // دالة اختيار الصورة من الاستوديو
  Future<void> _pickImage(bool isLicense) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // تقليل الجودة قليلاً لتسريع الرفع
    );

    if (pickedFile != null) {
      setState(() {
        if (isLicense) {
          _licenseImage = File(pickedFile.path);
        } else {
          _shopImage = File(pickedFile.path);
        }
      });
    }
  }

  // دالة معالجة التسجيل والرفع
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // فحص إجبارية رفع الصور للورشة
    if (_licenseImage == null || _shopImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى رفع صورة رخصة المهن وصورة واجهة الورشة للإثبات'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // استدعاء الدالة المحدثة من الـ AuthService
      await _authService.registerWorkshop(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        licenseImage: _licenseImage!,
        shopImage: _shopImage!,
      );

      if (mounted) {
        // إظهار صندوق الحوار (Dialog) اللي بيشرح خطوات التفعيل
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMsg = _authService.getErrorMessage(e.code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء رفع البيانات، حاول مجدداً'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // صندوق الحوار يظهر بعد نجاح العملية لتأكيد الإيميل
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3E53),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('تم استلام طلبك بنجاح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'خطوات تفعيل حساب ورشتك:',
              style: TextStyle(color: Color(0xFFF39C12), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'تم إرسال رابط تحقق إلى بريدك الإلكتروني، يرجى فتحه والضغط على الرابط لتأكيد وتفعيل الحساب الخاص بك لتتمكن من تسجيل الدخول.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WorkshopLoginScreen()),
              );
            },
            child: const Text('موافق، فهمت', style: TextStyle(color: Color(0xFFF39C12), fontWeight: FontWeight.bold, fontSize: 16)),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.add_business_rounded, // أيقونة متجر بسيطة ومتناسقة
                          size: 40,
                          color: Color(0xFFF39C12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'سجل ورشتك معنا',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'أدخل بيانات ورشتك وارفع الوثائق المطلوبة للانضمام إلى شبكتنا.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField(controller: _nameController, hintText: 'اسم الورشة التجاري', icon: Icons.business_rounded),
                const SizedBox(height: 16),
                _buildTextField(controller: _emailController, hintText: 'البريد الإلكتروني المهني', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField(controller: _phoneController, hintText: 'رقم هاتف الورشة / التواصل', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField(controller: _passwordController, hintText: 'كلمة المرور', icon: Icons.lock_outline, isPassword: true),
                
                const SizedBox(height: 24),
                const Text('الوثائق وإثباتات الملكية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 12),

                // أزرار رفع صور الإثباتات (رخصة المهن + واجهة المحل)
                Row(
                  children: [
                    Expanded(child: _buildImagePickerButton('صورة رخصة المهن', _licenseImage, () => _pickImage(true))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildImagePickerButton('واجهة الورشة', _shopImage, () => _pickImage(false))),
                  ],
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF39C12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('تقديم طلب التسجيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: (val) => val == null || val.isEmpty ? 'هذا الحقل مطلوب' : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF2D3E53),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF39C12), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildImagePickerButton(String label, File? imageFile, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF2D3E53),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: imageFile != null ? const Color(0xFFF39C12) : Colors.white10, width: 1.5),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(imageFile, fit: BoxFit.cover, width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Color(0xFFF39C12), size: 32),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
      ),
    );
  }
}