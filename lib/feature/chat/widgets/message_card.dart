import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:tuyage/common/enum/message_status.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/enum/message_type.dart' as myMessageType;
import 'package:tuyage/feature/chat/widgets/video_player_item.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.isSender,
    required this.haveNip,
    required this.message,
    required this.type,
    required this.timeSent,
    required this.status,
    required this.username,
    required this.repliedText,
    required this.repliedMessageType,
    required this.onLeftSwipe,
    required this.onRightSwipe,
  });

  final bool isSender;
  final bool haveNip;
  final String message;
  final DateTime timeSent;
  final MessageStatus status;
  final myMessageType.MessageType type;
  final VoidCallback onLeftSwipe;
  final VoidCallback onRightSwipe;
  final String username;
  final String repliedText;
  final myMessageType.MessageType repliedMessageType;

  @override
  Widget build(BuildContext context) {
    bool isPlaying = false;
    final AudioPlayer audioPlayer = AudioPlayer();
    final isReplying = repliedText.isNotEmpty;
    return SwipeTo(
      onLeftSwipe: (details) => onLeftSwipe(),
      onRightSwipe: (details) => onRightSwipe(),
      child: Container(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isSender
              ? 80
              : haveNip
                  ? 10
                  : 15,
          right: isSender
              ? haveNip
                  ? 10
                  : 15
              : 80,
        ),
        child: ClipPath(
          clipper: haveNip
              ? UpperNipMessageClipperTwo(
                  isSender ? MessageType.send : MessageType.receive,
                  nipWidth: 8,
                  nipHeight: 10,
                  bubbleRadius: haveNip ? 5 : 0,
                )
              : null,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isSender
                      ? context.theme.senderChatCardBg
                      : context.theme.receiverChatCardBg,
                  borderRadius: haveNip ? null : BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: type == myMessageType.MessageType.image
                      ? Padding(
                          padding:
                              const EdgeInsets.only(right: 3, left: 3, top: 3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(imageUrl: message),
                          ),
                        )
                      : type == myMessageType.MessageType.video
                          ? VideoPlayerItem(
                              videoUrl: message,
                            )
                          : type == myMessageType.MessageType.gif
                              ? CachedNetworkImage(imageUrl: message)
                              : type == myMessageType.MessageType.text
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                        top: 8,
                                        bottom: 8,
                                        left: isSender ? 10 : 15,
                                        right: isSender ? 15 : 10,
                                      ),
                                      child: Column(
                                        children: [
                                          if (isReplying) ...[
                                            Text(
                                              username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 3,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: context.theme.greyColor!
                                                    .withOpacity(0.5),
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  Radius.circular(5),
                                                ),
                                              ),
                                              child: repliedMessageType ==
                                                      myMessageType
                                                          .MessageType.text
                                                  ? Text(repliedText)
                                                  : repliedMessageType ==
                                                          myMessageType
                                                              .MessageType.image
                                                      ? CachedNetworkImage(
                                                          imageUrl: message)
                                                      : const Text(
                                                          'Comming Soon'),
                                            ),
                                            const SizedBox(
                                              height: 3,
                                            ),
                                          ],
                                          Text(
                                            message,
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    )
                                  : type == myMessageType.MessageType.audio
                                      ? StatefulBuilder(
                                          builder: (context, setState) {
                                          return IconButton(
                                            constraints: const BoxConstraints(
                                                minWidth: 100),
                                            onPressed: () async {
                                              if (isPlaying) {
                                                await audioPlayer.pause();
                                                setState(() {
                                                  isPlaying = false;
                                                });
                                              } else {
                                                await audioPlayer
                                                    .play(UrlSource(message));
                                                setState(() {
                                                  isPlaying = true;
                                                });
                                              }
                                            },
                                            icon: Icon(
                                              isPlaying
                                                  ? Icons.pause_circle
                                                  : Icons.play_circle,
                                            ),
                                          );
                                        })
                                      : const Text(
                                          'Iyi Type Ntayo turashiramwo'),
                ),
              ),
              Positioned(
                bottom: type == myMessageType.MessageType.text ? 8 : 4,
                right: type == myMessageType.MessageType.text
                    ? isSender
                        ? 15
                        : 10
                    : 4,
                child: type == myMessageType.MessageType.text
                    ? Text(
                        DateFormat.Hm().format(timeSent),
                        style: TextStyle(
                          fontSize: 9,
                          color: context.theme.greyColor,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.only(
                            left: 90, right: 10, bottom: 10, top: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(0, -1),
                            end: const Alignment(1, 1),
                            colors: [
                              context.theme.greyColor!.withOpacity(0),
                              context.theme.greyColor!.withOpacity(.3),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(300),
                            bottomRight: Radius.circular(100),
                          ),
                        ),
                        child: Text(
                          DateFormat.Hm().format(timeSent),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              if (isSender)
                Positioned(
                  right: 6,
                  bottom: type == myMessageType.MessageType.image ? 4 : 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == MessageStatus.pending)
                        const Icon(
                          Icons.pending,
                          color: Colors.white,
                          size: 15,
                        ),
                      if (status == MessageStatus.sent)
                        const Icon(
                          Icons.done,
                          color: Colors.white,
                          size: 15,
                        ),
                      if (status == MessageStatus.delivered)
                        const Icon(
                          Icons.done_all,
                          color: Colors.white,
                          size: 15,
                        ),
                      if (status == MessageStatus.read)
                        const Icon(
                          Icons.done_all,
                          color: Colors.blue,
                          size: 15,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
