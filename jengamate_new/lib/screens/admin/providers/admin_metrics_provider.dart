import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminMetricsProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  Timer? _timer;

  int pendingWithdrawals = 0;
  int pendingReferrals = 0;
  int openAuditItems = 0;
  int pendingUserApprovals = 0;
  bool loading = false;
  String? error;

  AdminMetricsProvider({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> fetchOnce() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<int>([
        _safeCount('withdrawals', field: 'status', equals: 'pending'),
        _safeCount('referrals', field: 'status', equals: 'pending'),
        _safeCount('audit_logs', field: 'status', equals: 'open'),
        _safeCount('users', field: 'approvalStatus', equals: 'pending'),
      ]);
      pendingWithdrawals = results[0];
      pendingReferrals = results[1];
      openAuditItems = results[2];
      pendingUserApprovals = results[3];
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => fetchOnce());
    // Trigger immediate fetch
    fetchOnce();
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  Future<int> _safeCount(String collection,
      {String? field, Object? equals}) async {
    try {
      Query query = _db.collection(collection);
      if (field != null && equals != null) {
        query = query.where(field, isEqualTo: equals);
      }
      // Try aggregate count on the filtered query
      try {
        // If running on SDKs that support aggregate queries
        final agg = await query.count().get();
        return agg.count ?? 0;
      } catch (_) {
        // Fallback: fetch minimal snapshot and use size
        final snap = await query.get();
        return snap.size;
      }
    } catch (_) {
      // Collection might not exist in dev; treat as zero
      return 0;
    }
  }
}
