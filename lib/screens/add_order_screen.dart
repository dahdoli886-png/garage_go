import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart'; // نحتاجه لاستخدام دالة رفع الصور
import '../services/order_service.dart';
import 'my_vehicles_screen.dart'; // مسار صفحة مركباتي لإضافة سيارة إذا لم يوجد

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _issueController = TextEditingController();
  
  final User? user = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  bool _remotePickup = false;
  bool _isLoading = false;
  
  String _selectedCategory = 'ميكانيك';
  String? _selectedVehicle; // لحفظ المركبة المختارة
  File? _issueImage; 

  final List<String> _categories = ['ميكانيك', 'كهرباء', 'تكييف', 'إطارات', 'سمكرة', 'أخرى'];

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  // دالة اختيار الصورة من الاستوديو
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _issueImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showModernSnackBar('حدث خطأ أثناء اختيار الصورة', Colors.redAccent);
    }
  }

  // دالة إرسال الطلب وحفظه في Firestore
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicle == null) {
      _showModernSnackBar('يرجى اختيار المركبة أولاً', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = '';
      
      // إذا اختار العميل صورة، نرفعها أولاً لـ Cloudinary
      if (_issueImage != null) {
        imageUrl = await _authService.uploadImage(_issueImage!, 'order_issues', user!.uid);
      }

      // حفظ الطلب في Firestore مباشرة
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user!.uid,
        'carModel': _selectedVehicle,
        'category': _selectedCategory,
        'issueDescription': _issueController.text.trim(),
        'issueImageUrl': imageUrl,
        'remotePickup': _remotePickup,
        'status': 'pending', // حالة الطلب المبدئية
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        _showModernSnackBar('تم إرسال طلبك بنجاح، بانتظار الورشة!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showModernSnackBar('حدث خطأ أثناء الإرسال: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showModernSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(color == Colors.green ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        elevation: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Column(
        children: [
          // =========================================
          // 1. الهيدر العصري
          // =========================================
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب صيانة', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('أخبرنا بمشكلة سيارتك لنساعدك', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // =========================================
          // 2. محتوى الفورم
          // =========================================
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- 1. تصنيف المشكلة ---
                    const Text('نوع الخدمة المطلوبة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ChoiceChip(
                              label: Text(category, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              selected: isSelected,
                              selectedColor: const Color(0xFFF59E0B),
                              backgroundColor: const Color(0xFF334155).withOpacity(0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide.none,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedCategory = category);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- 2. اختيار المركبة (من الفايربيس) ---
                    const Text('اختر المركبة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('vehicles').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFF334155).withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                const Icon(Icons.car_crash_rounded, color: Colors.white54),
                                const SizedBox(width: 12),
                                const Expanded(child: Text('لا يوجد مركبات مضافة', style: TextStyle(color: Colors.white54))),
                                TextButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVehiclesScreen())),
                                  child: const Text('إضافة مركبة', style: TextStyle(color: Color(0xFFF59E0B))),
                                )
                              ],
                            ),
                          );
                        }

                        final vehicles = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          value: _selectedVehicle,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFF59E0B)),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.directions_car_rounded, color: Color(0xFFF59E0B), size: 22),
                            filled: true,
                            fillColor: const Color(0xFF334155).withOpacity(0.4),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          ),
                          items: vehicles.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final carName = '${data['brand']} ${data['model']} (${data['plateNumber']})';
                            return DropdownMenuItem(value: carName, child: Text(carName));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedVehicle = val),
                          validator: (val) => val == null ? 'يرجى اختيار مركبة' : null,
                          hint: const Text('اضغط لاختيار مركبتك', style: TextStyle(color: Colors.white38)),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- 3. حقل التفاصيل ---
                    const Text('تفاصيل العطل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: _issueController,
                      hint: 'يرجى كتابة تفاصيل المشكلة أو الأعراض بدقة...',
                      icon: Icons.handyman_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // --- 4. إرفاق صورة (مفعلة) ---
                    const Text('إرفاق صورة للعطل (اختياري)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _issueImage != null ? const Color(0xFFF59E0B) : Colors.white24, width: 1.5),
                        ),
                        child: _issueImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(_issueImage!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, color: Color(0xFFF59E0B), size: 32),
                                  SizedBox(height: 8),
                                  Text('اضغط لإرفاق صورة لضوء الإنذار أو الخراب', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- 5. كرت الاستلام التفاعلي ---
                    const Text('خدمة الاستلام', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() => _remotePickup = !_remotePickup),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _remotePickup ? const Color(0xFFF59E0B).withOpacity(0.15) : const Color(0xFF334155).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _remotePickup ? const Color(0xFFF59E0B) : Colors.transparent, width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _remotePickup ? const Color(0xFFF59E0B) : const Color(0xFF0F172A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.delivery_dining_rounded, color: _remotePickup ? Colors.white : Colors.white54, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'استلام السيارة من موقعي',
                                        style: TextStyle(color: _remotePickup ? const Color(0xFFF59E0B) : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('سيتوجه المندوب لاستلام سيارتك', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (_remotePickup) const Icon(Icons.check_circle_rounded, color: Color(0xFFF59E0B), size: 28),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- 6. الزر المشع (Glowing Button) ---
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _isLoading ? null : _submitOrder,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('تأكيد وإرسال الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  SizedBox(width: 12),
                                  Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // تصميم حقول الإدخال
  // =========================================
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: (val) => val == null || val.isEmpty ? 'هذا الحقل مطلوب' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 40.0 : 0),
          child: Icon(icon, color: const Color(0xFFF59E0B), size: 22),
        ),
        filled: true,
        fillColor: const Color(0xFF334155).withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      ),
    );
  }
}