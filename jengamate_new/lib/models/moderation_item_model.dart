import 'package:jengamate/models/enums/moderation_status.dart';

class ModerationItem {
  final String id;
  final ModerationStatus status;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModerationItem({
    required this.id,
    required this.status,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModerationItem.fromMap(Map<String, dynamic> map) {
    return ModerationItem(
      id: map['id'],
      status: ModerationStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => ModerationStatus.pending),
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status.name,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
