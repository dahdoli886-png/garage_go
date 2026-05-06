import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/order_service.dart';
import '../providers/auth_provider.dart';
import 'add_order_screen.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
    final orderService = OrderService();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: orderService.getMyOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('صار خطأ: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.car_repair, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ما في طلبات بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('اضغط + عشان تضيف طلب جديد',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data =
                  orders[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_car,
                                  color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                data['carModel'] ?? 'سيارة',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status)
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                  color: _getStatusColor(status)),
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
                        style:
                            const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (data['remotePickup'] == true)
                        const Row(
                          children: [
                            Icon(Icons.delivery_dining,
                                size: 16, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('استلام من الموقع',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue)),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AddOrderScreen(),
    ),
  );
},
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('طلب جديد',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}