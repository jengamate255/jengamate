import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/models/moderation_item_model.dart'; // Assuming you have this model

class SupabaseModerationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Streams all moderation items.
  Stream<List<ModerationItem>> streamModerationItems({String? status}) {
    var query = _supabase
        .from('moderation_items')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    return query.map((data) => data.map((item) => ModerationItem.fromMap(item)).toList());
  }

  /// Creates a new moderation item.
  Future<ModerationItem> createModerationItem(ModerationItem item) async {
    try {
      final response = await _supabase.from('moderation_items').insert({
        'status': item.status.name,
        'payload': item.payload,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();
      Logger.log('Supabase moderation item created: ${response['id']}');
      return ModerationItem.fromMap(response);
    } catch (e, st) {
      Logger.logError('Error creating Supabase moderation item', e, st);
      rethrow;
    }
  }

  /// Updates the status of a moderation item.
  Future<void> updateModerationItemStatus(String itemId, ModerationStatus newStatus, {Map<String, dynamic>? metadata}) async {
    try {
      await _supabase.from('moderation_items').update({
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
        if (metadata != null) 'metadata': metadata, // Merge or replace as needed
      }).eq('id', itemId);
      Logger.log('Supabase moderation item $itemId status updated to ${newStatus.name}');
    } catch (e, st) {
      Logger.logError('Error updating Supabase moderation item status', e, st);
      rethrow;
    }
  }

  // You might need more methods here based on your UI needs, e.g., fetching a single item, deleting.
}
