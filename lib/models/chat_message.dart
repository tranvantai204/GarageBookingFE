//
// import 'package:flutter/material.dart';
import 'message_status.dart';

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final String? messageType;
  final String? fileUrl;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isRead;
  final DateTime? deliveredAt;
  final DateTime? seenAt;
  final String? tripId;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.messageType,
    this.fileUrl,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isRead = false,
    this.deliveredAt,
    this.seenAt,
    this.tripId,
  });

  ChatMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? message,
    String? messageType,
    String? fileUrl,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isRead,
    DateTime? deliveredAt,
    DateTime? seenAt,
    String? tripId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      seenAt: seenAt ?? this.seenAt,
      tripId: tripId ?? this.tripId,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['_id'] ?? '',
      chatRoomId: json['chatRoomId'] ?? json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderRole: json['senderRole'] ?? '',
      message: json['message'] ?? json['content'] ?? '',
      messageType: json['messageType'],
      fileUrl: json['fileUrl'],
      timestamp:
          DateTime.tryParse(json['timestamp'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
      status: MessageStatusExtension.fromString(json['status'] ?? 'sent'),
      isRead: json['isRead'] ?? false,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      seenAt: json['seenAt'] != null ? DateTime.tryParse(json['seenAt']) : null,
      tripId: json['tripId'],
    );
  }
}
