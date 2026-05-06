import 'package:flutter/material.dart';
import '../services/order_service.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carModelController = TextEditingController();
  final _issueController = TextEditingController();
  bool _remotePickup = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _carModelController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await OrderService().addOrder(
        carModel: _carModelController.text,
        issueDescription: _issueController.text,
        remotePickup: _remotePickup,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الطلب بنجاح ✅'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('صار خطأ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب جديد',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── موديل السيارة ───────────────────────────────
              const Text('موديل السيارة',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _carModelController,
                decoration: InputDecoration(
                  hintText: 'مثال: تويوتا كامري 2022',
                  prefixIcon:
                      const Icon(Icons.directions_car, color: Colors.blue),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'أدخل موديل السيارة';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ─── وصف المشكلة ─────────────────────────────────
              const Text('وصف المشكلة',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _issueController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اوصف المشكلة بالتفصيل...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'أدخل وصف المشكلة';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ─── استلام عن بعد ───────────────────────────────
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('استلام السيارة من موقعك'),
                  subtitle: const Text(
                    'سائق رح يجي ياخذ سيارتك',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  secondary: const Icon(Icons.delivery_dining,
                      color: Colors.blue),
                  value: _remotePickup,
                  activeColor: Colors.blue,
                  onChanged: (val) =>
                      setState(() => _remotePickup = val),
                ),
              ),
              const SizedBox(height: 40),

              // ─── زر الإرسال ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submitOrder,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : const Text('إرسال الطلب',
                          style: TextStyle(
                              fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}