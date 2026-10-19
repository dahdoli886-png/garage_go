import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportItem {
  final String partName;
  final double price;
  final String priorityColor;
  bool isApproved;

  ReportItem({
    required this.partName,
    required this.price,
    required this.priorityColor,
    this.isApproved = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'partName': partName,
      'price': price,
      'priorityColor': priorityColor,
      'isApproved': isApproved,
    };
  }
}

class BillingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  double _laborCost = 40.0;

  List<ReportItem> _inspectionItems = [
    ReportItem(partName: "Front Brake Pads", price: 35.0, priorityColor: "Red"),
    ReportItem(
      partName: "Engine Oil & Filter",
      price: 25.0,
      priorityColor: "Red",
    ),
    ReportItem(partName: "Spark Plugs", price: 18.0, priorityColor: "Yellow"),
    ReportItem(partName: "Wiper Blades", price: 8.0, priorityColor: "Green"),
  ];

  bool get isLoading => _isLoading;
  double get laborCost => _laborCost;
  List<ReportItem> get inspectionItems => _inspectionItems;

  void toggleItemApproval(int index) {
    _inspectionItems[index].isApproved = !_inspectionItems[index].isApproved;
    notifyListeners();
  }

  double calculateGrandTotal() {
    double total = _laborCost;
    for (var item in _inspectionItems) {
      if (item.isApproved) {
        total += item.price;
      }
    }
    return total;
  }

  Future<bool> submitApprovedBilling(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      List<Map<String, dynamic>> itemsMap = _inspectionItems
          .map((item) => item.toMap())
          .toList();
      await _firestore.collection('service_orders').doc(orderId).update({
        'inspectionReport': itemsMap,
        'laborCost': _laborCost,
        'grandTotal': calculateGrandTotal(),
        'status': 'Fixing',
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
