import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/providers/message_reply_provider.dart';
import 'package:tuyage/common/enum/message_type.dart' as myMessageType;
import 'package:tuyage/feature/chat/widgets/video_player_item.dart';

class MessageReplyPreview extends ConsumerWidget {
  const MessageReplyPreview({Key? key}) : super(key: key);

  void cancelReply(WidgetRef ref) {
    ref.read(messageReplyProvider.state).update((state) => null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AudioPlayer audioPlayer = AudioPlayer();
    final messageReply = ref.watch(messageReplyProvider);
    bool isPlaying = false;
    return Container(
      width: 350,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.theme.greyColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  messageReply!.isMe ? "Jew" :'Undi',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                child: const Icon(
                  Icons.close,
                  size: 16,
                ),
                onTap: () => cancelReply(ref),
              )
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          messageReply.messageType == myMessageType.MessageType.image
              ? Padding(
                  padding: const EdgeInsets.only(right: 3, left: 3, top: 3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: messageReply.message),
                  ),
                )
              : messageReply.messageType == myMessageType.MessageType.video
                  ? VideoPlayerItem(
                      videoUrl: messageReply.message,
                    )
                  : messageReply.messageType == myMessageType.MessageType.gif
                      ? CachedNetworkImage(imageUrl: messageReply.message)
                      : messageReply.messageType ==
                              myMessageType.MessageType.audio
                          ? StatefulBuilder(builder: (context, setState) {
                              return IconButton(
                                constraints:
                                    const BoxConstraints(minWidth: 100),
                                onPressed: () async {
                                  if (isPlaying) {
                                    await audioPlayer.pause();
                                    setState(() {
                                      isPlaying = false;
                                    });
                                  } else {
                                    await audioPlayer
                                        .play(UrlSource(messageReply.message));
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
                          : Text(
                              messageReply.message,
                            ),
        ],
      ),
    );
  }
}
