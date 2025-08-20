import 'user.dart';

class ChatParticipant {
  final String id;
  final String name;
  final String role;
  final String? avatar;

  ChatParticipant({
    required this.id,
    required this.name,
    required this.role,
    this.avatar,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      role: json['role'] ?? 'user',
      avatar: json['avatar'],
    );
  }
}

class LastMessage {
  final String content;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final String messageType;

  LastMessage({
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.messageType,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      messageType: json['messageType'] ?? 'text',
    );
  }

  LastMessage copyWith({
    String? content,
    String? senderId,
    String? senderName,
    DateTime? timestamp,
    String? messageType,
  }) {
    return LastMessage(
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
    );
  }
}

class ChatRoom {
  final String id;
  final ChatParticipant participant;
  final LastMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  // Trạng thái hoạt động và đang soạn tin
  final bool isOnline;
  final bool isTyping;
  final DateTime? lastActiveAt;

  // Legacy fields for backward compatibility
  final String name;
  final List<User> participants;
  final List<String> participantNames;
  final List<String> participantRoles;
  final String? tripId;
  final String? tripRoute;
  final bool isActive;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.participant,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.isOnline = false,
    this.isTyping = false,
    this.lastActiveAt,
    // Legacy fields
    this.name = '',
    this.participants = const [],
    this.participantNames = const [],
    this.participantRoles = const [],
    this.tripId,
    this.tripRoute,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    // Handle both new format and legacy format
    final participantData = json['participant'] ?? {};

    return ChatRoom(
      id: json['id'] ?? json['_id'] ?? '',
      participant: ChatParticipant.fromJson(participantData),
      lastMessage: json['lastMessage'] != null
          ? LastMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      // Legacy fields for backward compatibility
      name: participantData['name'] ?? 'Unknown Chat',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
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
    ChatParticipant? participant,
    LastMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      participant: participant ?? this.participant,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
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
