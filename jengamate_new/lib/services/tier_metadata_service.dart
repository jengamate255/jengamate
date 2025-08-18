import 'package:cloud_firestore/cloud_firestore.dart';

class TierMeta {
  final String id;
  final String name;
  final String badgeColor; // hex or named string stored in tiers
  TierMeta({required this.id, required this.name, required this.badgeColor});
}

class TierMetadataService {
  TierMetadataService._();
  static final TierMetadataService instance = TierMetadataService._();

  final _cache = <String, TierMeta>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  Map<String, TierMeta> get cache => _cache;

  Future<Map<String, TierMeta>> loadAll() async {
    if (_loaded && _cache.isNotEmpty) return _cache;
    final snap = await FirebaseFirestore.instance.collection('commission_tiers').get();
    _cache.clear();
    for (final doc in snap.docs) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString();
      final badgeColor = (data['badgeColor'] ?? '').toString();
      _cache[doc.id] = TierMeta(id: doc.id, name: name, badgeColor: badgeColor);
    }
    _loaded = true;
    return _cache;
  }

  TierMeta? get(String id) => _cache[id];
}
