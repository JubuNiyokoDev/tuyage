import 'package:tuyage/common/enum/message_status.dart';
import 'package:tuyage/common/enum/message_type.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String textMessage;
  final MessageType type;
  final DateTime timeSent;
  final String messageId;
  final MessageStatus status;
  final String repliedMessage;
  final String repliedTo;
  final MessageType repliedMessageType;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.textMessage,
    required this.type,
    required this.timeSent,
    required this.messageId,
    required this.status,
    required this.repliedMessage,
    required this.repliedTo,
    required this.repliedMessageType,
  });

  // Convertir un objet MessageModel en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'textMessage': textMessage,
      'type': type.type,
      'timeSent': timeSent.millisecondsSinceEpoch,
      'status': _getStringFromStatus(status),
      'repliedMessage': repliedMessage,
      'repliedTo': repliedTo,
      'repliedMessageType': repliedMessageType.type,
    };
  }

  // Factory pour créer un MessageModel à partir d'une Map
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      textMessage: map['textMessage'] ?? '',
      type: (map['type'] as String).toEnum(),
      timeSent: DateTime.fromMillisecondsSinceEpoch(map['timeSent']),
      messageId: map['messageId'] ?? '',
      status: _getStatusFromString(map['status'] ?? 'pending'),
      repliedMessage: map['repliedMessage'] ?? '',
      repliedTo: map['repliedTo'] ?? '',
      repliedMessageType: (map['repliedMessageType'] as String).toEnum(),
    );
  }

  static String _getStringFromStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.pending:
        return 'pending';
    }
  }

  static MessageStatus _getStatusFromString(String status) {
    switch (status) {
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.pending;
    }
  }
}
