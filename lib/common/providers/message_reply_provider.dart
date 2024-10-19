import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/enum/message_type.dart';

class MessageReply {
  final String message;
  final bool isMe;
  final MessageType messageType;

  MessageReply(this.message,this.isMe, this.messageType);
}

final messageReplyProvider = StateProvider<MessageReply?>((ref) => null);
