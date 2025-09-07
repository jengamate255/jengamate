import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:jengamate/services/hybrid_storage_service.dart';
import 'package:jengamate/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jengamate/utils/logger.dart';

class ImageMigrationScreen extends StatefulWidget {
  const ImageMigrationScreen({super.key});

  @override
  State<ImageMigrationScreen> createState() => _ImageMigrationScreenState();
}

class _ImageMigrationScreenState extends State<ImageMigrationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final HybridStorageService _hybridStorage;

  bool _running = false;
  bool _dryRun = true;
  int _batchSize = 20;
  int _migrated = 0;
  int _skipped = 0;
  int _failed = 0;
  int _examined = 0;
  String? _lastDocId; // pagination resume
  String _log = '';

  @override
  void initState() {
    super.initState();
    _hybridStorage = HybridStorageService(
      supabaseClient: Supabase.instance.client,
      firebaseStorageService: StorageService(),
    );
  }

  void _appendLog(String message) {
    Logger.log(message);
    setState(() {
      _log = (
        '${DateTime.now().toIso8601String()}  ' + message + '\n' + _log
      ).substring(0, _log.length + message.length + 35).toString();
    });
  }

  Future<bool> _runMigration() async {
    if (_running) return false;
    setState(() {
      _running = true;
    });

    try {
      Query query = _firestore.collection('products').orderBy(FieldPath.documentId);
      if (_lastDocId != null) {
        final doc = await _firestore.collection('products').doc(_lastDocId).get();
        if (doc.exists) {
          query = query.startAfterDocument(doc);
        }
      }
      query = query.limit(_batchSize);

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        _appendLog('No more products to examine. Migration pass complete.');
        setState(() {
          _running = false;
        });
        return false;
      }

      for (final doc in snapshot.docs) {
        _examined++;
        final data = doc.data() as Map<String, dynamic>;
        final String? imageUrl = (data['imageUrl'] as String?)?.trim();
        final bool alreadyMigrated = (data['imageMigrated'] == true);

        // Only migrate Firebase Storage URLs
        final isFirebaseUrl = imageUrl != null && imageUrl.contains('firebasestorage.googleapis.com');

        if (!isFirebaseUrl || alreadyMigrated) {
          _skipped++;
          continue;
        }

        try {
          _appendLog('Processing ${doc.id} ...');

          // Download bytes from existing URL
          Uint8List bytes = Uint8List(0);
          if (!_dryRun) {
            final resp = await http.get(Uri.parse(imageUrl));
            if (resp.statusCode != 200) {
              throw Exception('Download failed: ${resp.statusCode}');
            }
            bytes = resp.bodyBytes;
          }

          // Determine extension (best-effort)
          final ext = _guessExtFromUrl(imageUrl) ?? 'jpg';
          final fileName = '${doc.id}.$ext';

          // Upload to Supabase via HybridStorageService
          String? newUrl = imageUrl;
          if (!_dryRun) {
            newUrl = await _hybridStorage.uploadImage(
              fileName: fileName,
              folder: 'product_images',
              bytes: bytes,
            );
            if (newUrl == null) {
              throw Exception('Upload returned null URL');
            }
          }

          // Update Firestore record
          if (!_dryRun) {
            await doc.reference.update({
              'imageUrl': newUrl,
              'imageMigrated': true,
              'imageUrlOld': imageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          _migrated++;
          _appendLog('Migrated ${doc.id} -> $newUrl');
        } catch (e, st) {
          _failed++;
          Logger.logError('Migration failed for ${doc.id}', e, st);
          _appendLog('Failed ${doc.id}: $e');
        }
      }

      setState(() {
        _lastDocId = snapshot.docs.last.id;
      });

      _appendLog('Batch complete. Examined: $_examined, Migrated: $_migrated, Skipped: $_skipped, Failed: $_failed');
      return true;
    } finally {
      setState(() {
        _running = false;
      });
    }
  }

  Future<void> _runAll() async {
    // Run repeatedly until no more data
    String? previousLast = _lastDocId;
    while (true) {
      final hadData = await _runMigration();
      if (!hadData) break;
      if (_lastDocId == previousLast) {
        // Safety break to avoid infinite loop
        _appendLog('No progress detected, stopping auto-run.');
        break;
      }
      previousLast = _lastDocId;
      if (!mounted) break;
      await Future.delayed(const Duration(milliseconds: 150));
    }
    _appendLog('Run All complete. Examined: $_examined, Migrated: $_migrated, Skipped: $_skipped, Failed: $_failed');
  }

  Future<void> _auditRemaining() async {
    if (_running) return;
    setState(() {
      _running = true;
    });
    try {
      int remaining = 0;
      final List<String> sample = [];
      String? lastId;
      while (true) {
        Query q = _firestore.collection('products').orderBy(FieldPath.documentId);
        if (lastId != null) {
          final d = await _firestore.collection('products').doc(lastId).get();
          if (d.exists) {
            q = q.startAfterDocument(d);
          }
        }
        final snap = await q.limit(200).get();
        if (snap.docs.isEmpty) break;
        for (final doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String? url = (data['imageUrl'] as String?)?.trim();
          final bool migrated = (data['imageMigrated'] == true);
          final bool isFirebase = url != null && url.contains('firebasestorage.googleapis.com');
          if (isFirebase && !migrated) {
            remaining++;
            if (sample.length < 20) sample.add(doc.id);
          }
        }
        lastId = snap.docs.last.id;
      }
      _appendLog('Audit: Remaining Firebase imageUrl records = $remaining. Sample IDs: ${sample.join(', ')}');
    } catch (e, st) {
      Logger.logError('Audit failed', e, st);
      _appendLog('Audit failed: $e');
    } finally {
      setState(() {
        _running = false;
      });
    }
  }

  String? _guessExtFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final path = uri.path.toLowerCase();
    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'jpg';
    if (path.endsWith('.webp')) return 'webp';
    if (path.endsWith('.gif')) return 'gif';
    return null;
  }

  void _resetCounters() {
    setState(() {
      _migrated = 0;
      _skipped = 0;
      _failed = 0;
      _examined = 0;
      _lastDocId = null;
      _log = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Migration (Firebase -> Supabase)'),
        actions: [
          IconButton(
            tooltip: 'Reset counters',
            onPressed: _running ? null : _resetCounters,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(
                  value: _dryRun,
                  onChanged: _running
                      ? null
                      : (v) => setState(() => _dryRun = v),
                ),
                const SizedBox(width: 8),
                const Text('Dry run (no uploads or writes)'),
                const Spacer(),
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    initialValue: _batchSize.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Batch size',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0 && parsed <= 200) {
                        _batchSize = parsed;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(label: 'Examined', value: _examined),
                _MetricChip(label: 'Migrated', value: _migrated, color: Colors.green),
                _MetricChip(label: 'Skipped', value: _skipped, color: Colors.orange),
                _MetricChip(label: 'Failed', value: _failed, color: Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _running ? null : _runMigration,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_dryRun ? 'Run Batch (Dry Run)' : 'Run Batch'),
                ),
                const SizedBox(width: 12),
                if (_lastDocId != null)
                  OutlinedButton.icon(
                    onPressed: _running ? null : _runMigration,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Run Next Batch'),
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _running ? null : _runAll,
                  icon: const Icon(Icons.all_inclusive),
                  label: Text(_dryRun ? 'Run All (Dry Run)' : 'Run All'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _running ? null : _auditRemaining,
                  icon: const Icon(Icons.search),
                  label: const Text('Audit Remaining'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Logs'),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    _log.isEmpty ? 'No logs yet' : _log,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;
  const _MetricChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final Color base = color ?? Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.1),
        border: Border.all(color: base.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$value',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
