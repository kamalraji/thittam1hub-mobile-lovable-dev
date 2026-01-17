/// Connection model for representing a user connection
class Connection {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? otherUserHeadline;
  final String? otherUserOrganization;
  final String connectionType;
  final int matchScore;
  final DateTime connectedAt;
  final bool isOnline;
  final String status; // PENDING, ACCEPTED, DECLINED

  const Connection({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherUserHeadline,
    this.otherUserOrganization,
    required this.connectionType,
    this.matchScore = 0,
    required this.connectedAt,
    this.isOnline = false,
    required this.status,
  });

  factory Connection.fromMap(Map<String, dynamic> json, {
    required String currentUserId,
    Map<String, dynamic>? otherProfile,
  }) {
    final isRequester = json['requester_id'] == currentUserId;
    final otherUserId = isRequester 
        ? json['receiver_id'] as String 
        : json['requester_id'] as String;

    return Connection(
      id: json['id'] as String,
      otherUserId: otherUserId,
      otherUserName: otherProfile?['full_name'] as String? ?? 'Unknown',
      otherUserAvatar: otherProfile?['avatar_url'] as String?,
      otherUserHeadline: otherProfile?['headline'] as String?,
      otherUserOrganization: otherProfile?['organization'] as String?,
      connectionType: json['connection_type'] as String? ?? 'NETWORKING',
      matchScore: json['match_score'] as int? ?? 0,
      connectedAt: DateTime.parse(json['created_at'] as String),
      isOnline: otherProfile?['is_online'] as bool? ?? false,
      status: json['status'] as String? ?? 'PENDING',
    );
  }

  Connection copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? otherUserHeadline,
    String? otherUserOrganization,
    String? connectionType,
    int? matchScore,
    DateTime? connectedAt,
    bool? isOnline,
    String? status,
  }) => Connection(
    id: id ?? this.id,
    otherUserId: otherUserId ?? this.otherUserId,
    otherUserName: otherUserName ?? this.otherUserName,
    otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
    otherUserHeadline: otherUserHeadline ?? this.otherUserHeadline,
    otherUserOrganization: otherUserOrganization ?? this.otherUserOrganization,
    connectionType: connectionType ?? this.connectionType,
    matchScore: matchScore ?? this.matchScore,
    connectedAt: connectedAt ?? this.connectedAt,
    isOnline: isOnline ?? this.isOnline,
    status: status ?? this.status,
  );

  bool get isAccepted => status == 'ACCEPTED';
  bool get isPending => status == 'PENDING';
}
