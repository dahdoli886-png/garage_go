import 'package:flutter_test/flutter_test.dart';
import 'package:garage_go/services/order_service.dart';
import 'package:garage_go/services/inspection_service.dart';
import 'package:garage_go/models/inspection_item_model.dart';
import 'package:garage_go/models/inspection_report_model.dart';

Map<String, dynamic> order(String status) => {
  'status': status,
  'workshopId': 'shop',
  'inspectionReportId': 'report',
  'inspectionStatus': 'reviewed',
};
Map<String, dynamic> part(
  String id,
  String decision, {
  String condition = 'red',
}) => {
  'id': id,
  'condition': condition,
  'approvalStatus': decision,
  'partPrice': 0,
  'laborCost': 0,
};
Map<String, dynamic> report(List<Map<String, dynamic>> items) => {
  'orderId': 'order',
  'workshopId': 'shop',
  'status': 'reviewed',
  'items': items,
};
void check(
  String current,
  String next, {
  Map<String, dynamic>? data,
  Map<String, dynamic>? inspection,
  String uid = 'shop',
}) {
  WorkshopWorkflow.validate(
    order: data ?? order(current),
    report: inspection,
    orderId: 'order',
    uid: uid,
    newStatus: next,
  );
}

void main() {
  final approved = report([part('a', 'approved')]);
  test(
    'Accepted -> inspecting -> fixing -> completed with free approved repair',
    () {
      check('accepted', 'inspecting');
      check('inspecting', 'fixing', inspection: approved);
      check('fixing', 'completed', inspection: approved);
    },
  );
  test('All rejected and green-only can complete without repairs', () {
    check(
      'inspecting',
      'completed',
      inspection: report([part('a', 'rejected')]),
    );
    check(
      'inspecting',
      'completed',
      inspection: report([part('a', 'notRequired', condition: 'green')]),
    );
  });
  test('Legacy ready -> completed requires ownership, not a new report', () {
    check(
      'ready',
      'completed',
      data: {'status': 'ready', 'workshopId': 'shop'},
    );
    expect(
      () => check('ready', 'completed', uid: 'other'),
      throwsA(isA<WorkshopWorkflowException>()),
    );
  });
  test(
    'No new ready, skipped, backward, repeated or post-completion transitions',
    () {
      for (final transition in [
        ['accepted', 'fixing'],
        ['inspecting', 'completed'],
        ['fixing', 'inspecting'],
        ['fixing', 'fixing'],
        ['completed', 'completed'],
        ['accepted', 'ready'],
        ['inspecting', 'ready'],
        ['fixing', 'ready'],
        ['ready', 'ready'],
      ]) {
        expect(
          () => check(transition[0], transition[1], inspection: approved),
          throwsA(isA<WorkshopWorkflowException>()),
        );
      }
    },
  );
  test(
    'Pending, rejected-only, malformed and mismatched reports cannot start repairs',
    () {
      for (final value in <Map<String, dynamic>?>[
        null,
        report([part('a', 'pending')]),
        report([part('a', 'rejected')]),
        {...approved, 'status': 'awaitingApproval'},
        {...approved, 'orderId': 'other'},
        {...approved, 'workshopId': 'other'},
        report([part('a', 'approved'), part('a', 'approved')]),
        report([
          {...part('a', 'approved'), 'id': ''},
        ]),
        report([part('a', 'unknown')]),
      ]) {
        expect(
          () => check('inspecting', 'fixing', inspection: value),
          throwsA(isA<WorkshopWorkflowException>()),
        );
      }
    },
  );
  test(
    'Parent review/link and ownership are checked again against latest data',
    () {
      for (final value in [
        {...order('inspecting'), 'inspectionStatus': 'awaitingApproval'},
        {...order('inspecting'), 'inspectionReportId': ''},
        {...order('inspecting'), 'workshopId': 'other'},
        order('completed'),
      ]) {
        expect(
          () =>
              check('inspecting', 'fixing', data: value, inspection: approved),
          throwsA(isA<WorkshopWorkflowException>()),
        );
      }
    },
  );
  test(
    'Green-only creation is reviewed; red/orange creation awaits decisions',
    () {
      const healthy = InspectionItem(
        id: 'g',
        name: 'Healthy',
        condition: PartCondition.green,
        notes: '',
        partPrice: 50,
        laborCost: 50,
        approvalStatus: PartApprovalStatus.notRequired,
      );
      expect(healthy.totalCost, 0);
      expect(
        InspectionService.initialReportStatus([healthy]),
        InspectionReportStatus.reviewed,
      );
      for (final condition in [PartCondition.red, PartCondition.orange]) {
        expect(
          InspectionService.initialReportStatus([
            healthy.copyWith(
              condition: condition,
              approvalStatus: PartApprovalStatus.pending,
            ),
          ]),
          InspectionReportStatus.awaitingApproval,
        );
      }
    },
  );
}
