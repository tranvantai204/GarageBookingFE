class ChatRoom {
  final String id;
  final String name;
  final List<String> participants;
  final List<String> participantNames;
  final List<String> participantRoles;
  final String? tripId;
  final String? tripRoute;
  final String? lastMessage;
  final int unreadCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.name,
    required this.participants,
    required this.participantNames,
    required this.participantRoles,
    this.tripId,
    this.tripRoute,
    this.lastMessage,
    this.unreadCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      participantNames: List<String>.from(json['participantNames'] ?? []),
      participantRoles: List<String>.from(json['participantRoles'] ?? []),
      tripId: json['tripId'],
      tripRoute: json['tripRoute'],
      lastMessage: json['lastMessage'],
      unreadCount: json['unreadCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'participants': participants,
      'participantNames': participantNames,
      'participantRoles': participantRoles,
      'tripId': tripId,
      'tripRoute': tripRoute,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    List<String>? participants,
    List<String>? participantNames,
    List<String>? participantRoles,
    String? tripId,
    String? tripRoute,
    String? lastMessage,
    int? unreadCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantRoles: participantRoles ?? this.participantRoles,
      tripId: tripId ?? this.tripId,
      tripRoute: tripRoute ?? this.tripRoute,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ChatRoom(id: $id, name: $name, participants: $participants)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatRoom && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
