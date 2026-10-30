import 'package:flutter_test/flutter_test.dart';
import 'package:garage_go/models/inspection_item_model.dart';
import 'package:garage_go/models/inspection_report_model.dart';
import 'package:garage_go/services/inspection_service.dart';

Map<String, dynamic> item(
  String id, {
  String condition = 'red',
  String approval = 'pending',
}) => {
  'id': id,
  'name': 'Part $id',
  'condition': condition,
  'partPrice': condition == 'green' ? 0.0 : 12.0,
  'laborCost': condition == 'green' ? 0.0 : 3.0,
  'approvalStatus': approval,
  'notes': 'Preserve notes',
  'imageUrl': 'https://example.com/part.png',
  'legacyField': {'keep': true},
};

void main() {
  test(
    'Approving one item preserves prices, unknown fields and other items',
    () {
      final source = [item('a'), item('b', condition: 'orange')];
      final result = InspectionService.prepareItemDecision(
        rawItems: source,
        itemId: 'a',
        decision: PartApprovalStatus.approved,
      );
      expect(result.items[0], {...source[0], 'approvalStatus': 'approved'});
      expect(result.items[1], source[1]);
      expect(source[0]['approvalStatus'], 'pending');
      expect(result.reviewed, isFalse);
    },
  );

  test('Final rejection reviews report; green does not delay review', () {
    final result = InspectionService.prepareItemDecision(
      rawItems: [
        item('a', approval: 'approved'),
        item('b', condition: 'orange'),
        item('c', condition: 'green', approval: 'notRequired'),
      ],
      itemId: 'b',
      decision: PartApprovalStatus.rejected,
    );
    expect(result.reviewed, isTrue);
    expect(result.items[1]['approvalStatus'], 'rejected');
  });

  test('Repeated and conflicting decisions are rejected', () {
    for (final decision in [
      PartApprovalStatus.approved,
      PartApprovalStatus.rejected,
    ]) {
      expect(
        () => InspectionService.prepareItemDecision(
          rawItems: [item('a', approval: 'approved')],
          itemId: 'a',
          decision: decision,
        ),
        throwsA(isA<InspectionDecisionException>()),
      );
    }
  });

  test('Green, missing IDs and duplicate IDs cannot receive decisions', () {
    for (final raw in [
      [item('a', condition: 'green', approval: 'notRequired')],
      [item('b')],
      [item('a'), item('a')],
    ]) {
      expect(
        () => InspectionService.prepareItemDecision(
          rawItems: raw,
          itemId: 'a',
          decision: PartApprovalStatus.approved,
        ),
        throwsA(isA<InspectionDecisionException>()),
      );
    }
  });

  test('Invalid decisions and malformed legacy data fail without mutation', () {
    expect(
      () => InspectionService.prepareItemDecision(
        rawItems: [item('a')],
        itemId: 'a',
        decision: PartApprovalStatus.pending,
      ),
      throwsA(isA<InspectionDecisionException>()),
    );
    for (final raw in [
      null,
      [],
      ['bad'],
      [
        {...item('a'), 'condition': 'unknown'},
      ],
      [
        {...item('a'), 'partPrice': double.nan},
      ],
      [
        {...item('a'), 'laborCost': -1},
      ],
      [
        {...item('a'), 'approvalStatus': 'unknown'},
      ],
    ]) {
      expect(
        () => InspectionService.prepareItemDecision(
          rawItems: raw,
          itemId: 'a',
          decision: PartApprovalStatus.rejected,
        ),
        throwsA(isA<InspectionDecisionException>()),
      );
    }
  });

  test('Approved total excludes pending, rejected and healthy items', () {
    final report = InspectionReport(
      id: 'report',
      orderId: 'order',
      workshopId: 'workshop',
      status: InspectionReportStatus.awaitingApproval,
      createdAt: DateTime(2026),
      items: [
        InspectionItem.fromMap(item('a', approval: 'approved')),
        InspectionItem.fromMap(
          item('b', condition: 'orange', approval: 'approved'),
        ),
        InspectionItem.fromMap(item('c')),
        InspectionItem.fromMap(item('d', approval: 'rejected')),
        const InspectionItem(
          id: 'e',
          name: 'Healthy',
          condition: PartCondition.green,
          notes: '',
          partPrice: 100,
          laborCost: 100,
          approvalStatus: PartApprovalStatus.notRequired,
        ),
      ],
    );
    expect(report.totalEstimatedCost, 60);
    expect(report.totalApprovedCost, 30);
    expect(report.items.last.totalCost, 0);
  });

  test('Unknown legacy conditions never silently become healthy', () {
    expect(
      () => InspectionItem.fromMap({...item('a'), 'condition': 'unknown'}),
      throwsFormatException,
    );
  });
}
