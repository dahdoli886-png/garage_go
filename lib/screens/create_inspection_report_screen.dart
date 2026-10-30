import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/inspection_item_model.dart';
import '../services/inspection_service.dart';

class CreateInspectionReportScreen extends StatefulWidget {
  final String orderId;

  const CreateInspectionReportScreen({super.key, required this.orderId});

  @override
  State<CreateInspectionReportScreen> createState() =>
      _CreateInspectionReportScreenState();
}

class _CreateInspectionReportScreenState
    extends State<CreateInspectionReportScreen> {
  static const Color bg = Color(0xFF070D18);
  static const Color surface = Color(0xFF0D1B2A);
  static const Color border = Color(0xFF1E3A5F);
  static const Color orange = Color(0xFFFF6B35);
  static const Color gold = Color(0xFFF5A623);
  static const Color textColor = Color(0xFFE8EDF5);
  static const Color muted = Color(0xFF94A3B8);

  final List<InspectionItem> _items = [];
  final _inspectionService = InspectionService();
  bool _isSaving = false;
  bool _isAddingItem = false;
  bool _reportSaved = false;

  String _saveError(Object error) {
    if (error is StateError) {
      return switch (error.message) {
        'Please log in first.' => 'يرجى تسجيل الدخول مجدداً.',
        'Order not found.' => 'الطلب غير موجود.',
        'You are not assigned to this order.' => 'هذا الطلب غير تابع لورشتك.',
        'Order must be in inspecting status.' =>
          'يجب أن يكون الطلب في حالة جاري الفحص.',
        'An inspection report already exists for this order.' =>
          'يوجد تقرير محفوظ لهذا الطلب بالفعل. ارجع لعرضه من شاشة الورشة.',
        _ => 'تحقق من بيانات القطع وحالات الموافقة ثم حاول مجدداً.',
      };
    }
    if (error is ArgumentError) {
      return 'أضف قطعة واحدة على الأقل وتحقق من أسماء القطع والأسعار.';
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'لا تملك صلاحية حفظ التقرير. راجع صلاحيات Firestore.';
    }
    return 'تعذر حفظ التقرير. تحقق من الاتصال وحاول مجدداً.';
  }

  Future<void> _saveReport() async {
    if (_isSaving || _reportSaved || _isAddingItem) {
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف قطعة واحدة على الأقل قبل حفظ التقرير.'),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      await _inspectionService.createReport(
        orderId: widget.orderId,
        items: List<InspectionItem>.unmodifiable(_items),
      );
      if (!mounted) {
        return;
      }
      _reportSaved = true;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('تم حفظ التقرير وإرساله للزبون بنجاح.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_saveError(error))));
      }
    } finally {
      if (mounted && !_reportSaved) {
        setState(() => _isSaving = false);
      }
    }
  }

  double get _estimatedTotal =>
      _items.fold(0.0, (total, item) => total + item.totalCost);

  String _conditionLabel(PartCondition condition) {
    switch (condition) {
      case PartCondition.red:
        return '🔴 خطيرة - تحتاج إصلاح عاجل';
      case PartCondition.orange:
        return '🟠 مستهلكة - يُنصح بتغييرها';
      case PartCondition.green:
        return '🟢 سليمة - لا تحتاج إصلاح';
    }
  }

  Future<void> _addItem() async {
    if (_isSaving || _isAddingItem || _reportSaved) {
      return;
    }
    _isAddingItem = true;
    try {
      final item = await showDialog<InspectionItem>(
        context: context,
        builder: (_) => const _InspectionItemDialog(),
      );
      if (!mounted || item == null) {
        return;
      }
      setState(() => _items.add(item));
    } finally {
      _isAddingItem = false;
    }
  }

  Color _conditionColor(PartCondition condition) {
    switch (condition) {
      case PartCondition.red:
        return const Color(0xFFEF4444);
      case PartCondition.orange:
        return const Color(0xFFF59E0B);
      case PartCondition.green:
        return const Color(0xFF10B981);
    }
  }

  Widget _itemCard(InspectionItem item) {
    final color = _conditionColor(item.condition);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _items.remove(item));
                },
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          Text(_conditionLabel(item.condition), style: TextStyle(color: color)),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.notes, style: const TextStyle(color: muted)),
          ],
          if (item.imageUrl != null) ...[
            const SizedBox(height: 10),
            Image.network(
              item.imageUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Text(
                'تعذّر عرض الصورة',
                style: TextStyle(color: muted),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'سعر القطعة: ${item.partPrice.toStringAsFixed(2)} د.أ',
            style: const TextStyle(color: muted),
          ),
          Text(
            'أجرة العمل: ${item.laborCost.toStringAsFixed(2)} د.أ',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 8),
          Text(
            'المجموع: ${item.totalCost.toStringAsFixed(2)} د.أ',
            style: const TextStyle(color: gold, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: !_isSaving,
        child: AbsorbPointer(
          absorbing: _isSaving,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: surface,
              foregroundColor: textColor,
              title: const Text('تقرير فحص السيارة'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'رقم الطلب: ${widget.orderId}',
                        style: const TextStyle(color: muted),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'قطع السيارة',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'لم تتم إضافة أي قطع بعد',
                              style: TextStyle(color: muted),
                            ),
                          ),
                        ),
                      ..._items.map(_itemCard),
                      OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة قطعة'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: orange,
                          side: const BorderSide(color: orange),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: surface,
                    border: Border(top: BorderSide(color: border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'التكلفة التقديرية',
                              style: TextStyle(color: textColor),
                            ),
                            Text(
                              '${_estimatedTotal.toStringAsFixed(2)} د.أ',
                              style: const TextStyle(
                                color: gold,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text('جارٍ حفظ التقرير...'),
                                    ],
                                  )
                                : const Text('💾 حفظ وإرسال التقرير للزبون'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InspectionItemDialog extends StatefulWidget {
  const _InspectionItemDialog();

  @override
  State<_InspectionItemDialog> createState() => _InspectionItemDialogState();
}

class _InspectionItemDialogState extends State<_InspectionItemDialog> {
  static const bg = _CreateInspectionReportScreenState.bg;
  static const surface = _CreateInspectionReportScreenState.surface;
  static const border = _CreateInspectionReportScreenState.border;
  static const orange = _CreateInspectionReportScreenState.orange;
  static const textColor = _CreateInspectionReportScreenState.textColor;
  static const muted = _CreateInspectionReportScreenState.muted;

  final nameController = TextEditingController();
  final notesController = TextEditingController();
  final imageController = TextEditingController();
  final priceController = TextEditingController();
  final laborController = TextEditingController();
  PartCondition condition = PartCondition.red;

  @override
  void dispose() {
    // The dialog owns these controllers until its TextFields are unmounted.
    nameController.dispose();
    notesController.dispose();
    imageController.dispose();
    priceController.dispose();
    laborController.dispose();
    super.dispose();
  }

  String _conditionLabel(PartCondition condition) {
    switch (condition) {
      case PartCondition.red:
        return '🔴 خطيرة - تحتاج إصلاح عاجل';
      case PartCondition.orange:
        return '🟠 مستهلكة - يُنصح بتغييرها';
      case PartCondition.green:
        return '🟢 سليمة - لا تحتاج إصلاح';
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: muted),
      filled: true,
      fillColor: bg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: orange),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: textColor),
      decoration: _decoration(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: surface,
      title: const Text('إضافة قطعة للفحص', style: TextStyle(color: textColor)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameController, 'اسم القطعة'),
              const SizedBox(height: 12),
              DropdownButtonFormField<PartCondition>(
                initialValue: condition,
                dropdownColor: surface,
                style: const TextStyle(color: textColor),
                decoration: _decoration('حالة القطعة'),
                items: PartCondition.values.map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(_conditionLabel(value)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => condition = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              _field(notesController, 'ملاحظات الفني', maxLines: 3),
              const SizedBox(height: 12),
              _field(imageController, 'رابط الصورة (اختياري للتجربة)'),
              const SizedBox(height: 12),
              if (condition != PartCondition.green) ...[
                _field(priceController, 'سعر القطعة', numeric: true),
                const SizedBox(height: 12),
                _field(laborController, 'أجرة العمل', numeric: true),
              ] else
                const Text(
                  'القطعة السليمة لا تُضاف لها تكلفة إصلاح.',
                  style: TextStyle(color: muted),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final name = nameController.text.trim();
            final price = condition == PartCondition.green
                ? 0.0
                : double.tryParse(priceController.text.trim());
            final labor = condition == PartCondition.green
                ? 0.0
                : double.tryParse(laborController.text.trim());

            if (name.isEmpty ||
                price == null ||
                labor == null ||
                !price.isFinite ||
                !labor.isFinite ||
                price < 0 ||
                labor < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('أدخل اسم القطعة وأسعاراً صحيحة غير سالبة'),
                ),
              );
              return;
            }

            final newItem = InspectionItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name,
              condition: condition,
              imageUrl: imageController.text.trim().isEmpty
                  ? null
                  : imageController.text.trim(),
              notes: notesController.text.trim(),
              partPrice: price,
              laborCost: labor,
              approvalStatus: condition == PartCondition.green
                  ? PartApprovalStatus.notRequired
                  : PartApprovalStatus.pending,
            );

            FocusScope.of(context).unfocus();
            Navigator.pop(context, newItem);
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
