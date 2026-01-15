import 'package:flutter/foundation.dart';

@immutable
class ConnectionRequestItem {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final String connectionType;
  final DateTime createdAt;
  final int matchScore;

  const ConnectionRequestItem({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterAvatar,
    required this.connectionType,
    required this.createdAt,
    required this.matchScore,
  });
}
