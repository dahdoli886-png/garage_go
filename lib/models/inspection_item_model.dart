enum PartCondition { red, orange, green }

enum PartApprovalStatus { pending, approved, rejected, notRequired }

class InspectionItem {
  final String id;
  final String name;
  final PartCondition condition;
  final String? imageUrl;
  final String notes;
  final double partPrice;
  final double laborCost;
  final PartApprovalStatus approvalStatus;

  const InspectionItem({
    required this.id,
    required this.name,
    required this.condition,
    this.imageUrl,
    required this.notes,
    required double partPrice,
    required double laborCost,
    required this.approvalStatus,
  }) : partPrice = condition == PartCondition.green ? 0 : partPrice,
       laborCost = condition == PartCondition.green ? 0 : laborCost;

  // مجموع سعر القطعة وأجرة العمل
  double get totalCost => partPrice + laborCost;

  // هل القطعة بحاجة لموافقة الزبون؟
  bool get requiresApproval =>
      condition == PartCondition.red || condition == PartCondition.orange;

  // تحويل بيانات القطعة إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'condition': condition.name,
      'imageUrl': imageUrl,
      'notes': notes,
      'partPrice': partPrice,
      'laborCost': laborCost,
      'approvalStatus': approvalStatus.name,
    };
  }

  // قراءة بيانات القطعة من Firestore
  factory InspectionItem.fromMap(Map<String, dynamic> data) {
    final conditionName = data['condition'] as String? ?? '';
    if (!PartCondition.values.any((value) => value.name == conditionName) ||
        !PartApprovalStatus.values.any(
          (value) => value.name == data['approvalStatus'],
        )) {
      throw const FormatException(
        'Invalid inspection condition or approval status',
      );
    }

    final approvalName = data['approvalStatus'] as String? ?? 'pending';

    final condition = PartCondition.values.firstWhere(
      (value) => value.name == conditionName,
      orElse: () => PartCondition.green,
    );

    final approvalStatus = PartApprovalStatus.values.firstWhere(
      (value) => value.name == approvalName,
      orElse: () => PartApprovalStatus.pending,
    );

    return InspectionItem(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      condition: condition,
      imageUrl: data['imageUrl'] as String?,
      notes: data['notes'] as String? ?? '',
      partPrice: (data['partPrice'] as num?)?.toDouble() ?? 0.0,
      laborCost: (data['laborCost'] as num?)?.toDouble() ?? 0.0,
      approvalStatus: approvalStatus,
    );
  }

  // إنشاء نسخة معدّلة من القطعة
  InspectionItem copyWith({
    String? name,
    PartCondition? condition,
    String? imageUrl,
    String? notes,
    double? partPrice,
    double? laborCost,
    PartApprovalStatus? approvalStatus,
  }) {
    return InspectionItem(
      id: id,
      name: name ?? this.name,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      partPrice: partPrice ?? this.partPrice,
      laborCost: laborCost ?? this.laborCost,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }
}
