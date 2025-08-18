import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:jengamate/screens/admin/admin_tools_screen.dart';
import 'package:jengamate/screens/admin/providers/admin_metrics_provider.dart';

class _StubMetrics extends AdminMetricsProvider {
  _StubMetrics() : super(firestore: FakeFirebaseFirestore());

  void setValues({
    int withdrawals = 0,
    int referrals = 0,
    int audits = 0,
    int approvals = 0,
    bool isLoading = false,
    String? err,
  }) {
    pendingWithdrawals = withdrawals;
    pendingReferrals = referrals;
    openAuditItems = audits;
    pendingUserApprovals = approvals;
    loading = isLoading;
    error = err;
    notifyListeners();
  }
}

void main() {
  testWidgets('AdminToolsScreen shows KPIs and badges from provider', (tester) async {
    final stub = _StubMetrics();
    stub.setValues(withdrawals: 5, referrals: 2, audits: 3, approvals: 4);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminToolsScreen.withProvider(stub, autoRefresh: false),
      ),
    );

    // Allow first frame
    await tester.pumpAndSettle();

    // KPI labels
    expect(find.text('Pending Withdrawals'), findsOneWidget);
    expect(find.text('Pending Referrals'), findsOneWidget);
    expect(find.text('Open Audit Items'), findsOneWidget);
    expect(find.text('User Approvals'), findsOneWidget);

    // KPI values
    expect(find.text('5'), findsWidgets); // withdrawals
    expect(find.text('2'), findsWidgets); // referrals
    expect(find.text('3'), findsWidgets); // audits
    expect(find.text('4'), findsWidgets); // approvals

    // Tiles exist
    expect(find.text('Withdrawal Management'), findsOneWidget);
    expect(find.text('Referral Management'), findsOneWidget);
    expect(find.text('Financial Oversight'), findsOneWidget);
    expect(find.text('User Management'), findsOneWidget);
  });
}
