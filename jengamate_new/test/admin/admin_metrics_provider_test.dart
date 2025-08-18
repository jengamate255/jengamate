import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jengamate/screens/admin/providers/admin_metrics_provider.dart';

void main() {
  group('AdminMetricsProvider', () {
    test('fetchOnce aggregates counts correctly', () async {
      final fake = FakeFirebaseFirestore();

      // Seed withdrawals (2 pending, 1 approved)
      await fake.collection('withdrawals').add({'status': 'pending'});
      await fake.collection('withdrawals').add({'status': 'pending'});
      await fake.collection('withdrawals').add({'status': 'approved'});

      // Seed referrals (1 pending, 1 approved)
      await fake.collection('referrals').add({'status': 'pending'});
      await fake.collection('referrals').add({'status': 'approved'});

      // Seed audit logs (3 open, 1 closed)
      await fake.collection('audit_logs').add({'status': 'open'});
      await fake.collection('audit_logs').add({'status': 'open'});
      await fake.collection('audit_logs').add({'status': 'open'});
      await fake.collection('audit_logs').add({'status': 'closed'});

      // Seed users (2 pending approvals, 1 approved)
      await fake.collection('users').add({'approvalStatus': 'pending'});
      await fake.collection('users').add({'approvalStatus': 'pending'});
      await fake.collection('users').add({'approvalStatus': 'approved'});

      final provider = AdminMetricsProvider(firestore: fake);
      await provider.fetchOnce();

      expect(provider.pendingWithdrawals, 2);
      expect(provider.pendingReferrals, 1);
      expect(provider.openAuditItems, 3);
      expect(provider.pendingUserApprovals, 2);
      expect(provider.loading, false);
      expect(provider.error, isNull);
    });
  });
}
