import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';

class RepairApprovalScreen extends StatelessWidget {
  final String orderId;

  const RepairApprovalScreen({super.key, required this.orderId});

  Color _getPriorityColor(String colorStr) {
    switch (colorStr) {
      case 'Red':
        return Colors.red.shade400;
      case 'Yellow':
        return Colors.amber.shade600;
      case 'Green':
        return Colors.green.shade400;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingProvider = Provider.of<BillingProvider>(context);
    final items = billingProvider.inspectionItems;

    return Scaffold(
      backgroundColor: const Color(0xFF1A2436),
      appBar: AppBar(
        title: const Text(
          "تقرير الفحص والاعتماد الجزئي",
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: const Color(0xFF111823),
        centerTitle: true,
      ),
      body: billingProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return Card(
                          color: const Color(0xFF243044),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.handyman,
                              color: Colors.blue,
                            ),
                            title: const Text(
                              "أجور اليد العاملة (Labor Cost)",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              "${billingProvider.laborCost} JOD",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }

                      final item = items[index];
                      return Card(
                        color: const Color(0xFF243044),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Container(
                            width: 12,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(item.priorityColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(
                            item.partName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "الحالة: ${item.priorityColor}",
                            style: TextStyle(
                              color: _getPriorityColor(
                                item.priorityColor,
                              ).withAlpha(200),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${item.price} JOD",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Checkbox(
                                activeColor: const Color(0xFFFFA000),
                                checkColor: Colors.black,
                                value: item.isApproved,
                                onChanged: (bool? value) {
                                  billingProvider.toggleItemApproval(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111823),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "المجموع الكلي المعتمد:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              "${billingProvider.calculateGrandTotal().toStringAsFixed(2)} JOD",
                              style: const TextStyle(
                                color: Color(0xFFFFA000),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            bool success = await billingProvider
                                .submitApprovedBilling(orderId);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'تم إرسال الفاتورة وحفظها بنجاح في Firebase',
                                  ),
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'فشل في الاتصال بالسيرفر، حاول مجدداً',
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA000),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "إرسال الموافقة وبدء الإصلاح",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
