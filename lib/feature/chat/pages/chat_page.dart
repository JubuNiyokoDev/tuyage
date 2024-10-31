import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tuyage/common/enum/message_status.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/helper/last_seen_message.dart';
import 'package:tuyage/common/models/message_model.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/providers/message_reply_provider.dart';
import 'package:tuyage/common/routes/routes.dart';
import 'package:tuyage/common/widgets/custom_icon_button.dart';
import 'package:tuyage/feature/auth/controller/auth_controller.dart';
import 'package:tuyage/feature/call/controller/call_controller.dart';
import 'package:tuyage/feature/call/screens/call_pickup_screen.dart';
import 'package:tuyage/feature/chat/controller/chat_controller.dart';
import 'package:tuyage/feature/chat/repository/chat_repository.dart';
import 'package:tuyage/feature/chat/widgets/chat_text_field.dart';
import 'package:tuyage/feature/chat/widgets/message_card.dart';
import 'package:tuyage/feature/chat/widgets/show_date_card.dart';
import 'package:tuyage/feature/chat/widgets/yellow_card.dart';
import 'package:tuyage/common/enum/message_type.dart' as myMessageType;

final pageStorageBucket = PageStorageBucket();

class ChatPage extends ConsumerWidget {
  ChatPage({
    super.key,
    required this.name,
    required this.uid,
    required this.isGroupChat,
    required this.profileImage,
    required this.lastSeen,
    required this.user,
  });

  final String name;
  final String uid;
  final bool isGroupChat;
  final String profileImage;
  final int? lastSeen;
  final UserModel? user;
  final ScrollController scrollController = ScrollController();

  final ValueNotifier<bool> showScrollToBottomButton = ValueNotifier(false);
  void scrollToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void makeCall(WidgetRef ref, BuildContext context) {
    ref.read(callControllerProvider).makeCall(
          context,
          name,
          uid,
          profileImage,
          isGroupChat,
        );
  }

  void onMessageSwipe(String message, bool isMe,
      myMessageType.MessageType messageType, WidgetRef ref) {
    ref.read(messageReplyProvider.state).update(
          (state) => MessageReply(
            message,
            isMe,
            messageType,
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey lastMessageKey = GlobalKey();

    var firebaseUser = FirebaseAuth.instance.currentUser;
    final displayUsername = uid == firebaseUser!.uid ? '$name (You)' : name;
    final currentUserId = firebaseUser.uid;

    scrollController.addListener(() {
      final offset = scrollController.offset;
      final viewportHeight = scrollController.position.viewportDimension;
      final height = scrollController.position.maxScrollExtent;

      if (lastMessageKey.currentContext != null) {
        final RenderBox lastMessageBox =
            lastMessageKey.currentContext!.findRenderObject() as RenderBox;
        final double lastMessagePosition =
            lastMessageBox.localToGlobal(Offset.zero).dy;

        if (scrollController.offset >
            lastMessagePosition + scrollController.position.viewportDimension) {
          showScrollToBottomButton.value = true;
        } else {
          showScrollToBottomButton.value = false;
        }
      }
      if (offset >= height - viewportHeight) {
        if (!isGroupChat) {
          ref.read(chatControllerProvider).getMessages(uid).listen((messages) {
            for (final message in messages) {
              if (message.senderId != currentUserId &&
                  message.status != MessageStatus.read) {
                ref.read(chatControllerProvider).updateMessageStatusToRead(
                      messageId: message.messageId,
                      senderId: message.senderId,
                    );
              }
            }
          });
        }
      }
    });

    return CallPickupScreen(
      scaffold: Scaffold(
        backgroundColor: context.theme.chatPageBgColor,
        appBar: AppBar(
          leading: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                const Icon(Icons.arrow_back),
                Hero(
                  tag: 'profile',
                  child: Container(
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(profileImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: InkWell(
            onTap: () async {
              if (isGroupChat) {
                Navigator.pushNamed(
                  context,
                  Routes.groupProfile,
                  arguments: {
                    'groupName': name,
                    'uid': uid,
                  },
                );
              } else {
                Navigator.pushNamed(
                  context,
                  Routes.profile,
                  arguments: user,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isGroupChat
                      ? Text(
                          name,
                        )
                      : Text(
                          displayUsername.isNotEmpty
                              ? displayUsername
                              : 'Loading...',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                  const SizedBox(height: 3),
                  !isGroupChat
                      ? StreamBuilder<ConnectivityResult>(
                          stream: ref
                              .read(authControllerProvider)
                              .getUserPresenceStatus(uid: uid),
                          builder: (_, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.active) {
                              final getlastSeen =
                                  lastSeenMessage(lastSeen ?? 0);
                              uid == currentUserId
                                  ? 'Wiyandikire wewe nyene'
                                  : getlastSeen;

                              return Text(
                                "haciye $getlastSeen",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              print('Error: ${snapshot.error}');
                              return const Text(
                                'Error',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Text(
                                'No data',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              );
                            }

                            final ConnectivityResult connectivityResult =
                                snapshot.data!;

                            final bool isConnected = connectivityResult ==
                                    ConnectivityResult.mobile ||
                                connectivityResult == ConnectivityResult.wifi;

                            final lastMessage = lastSeenMessage(lastSeen ?? 0);
                            final displayLasteSeen = uid == currentUserId
                                ? 'Wiyandikire wewe nyene'
                                : "haciye $lastMessage";

                            return Text(
                              isConnected ? 'online' : displayLasteSeen,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      : Container(),
                ],
              ),
            ),
          ),
          actions: currentUserId != uid
              ? [
                  CustomIconButton(
                    onPressed: () => makeCall(ref, context),
                    icon: Icons.video_call,
                    iconColor: Colors.white,
                  ),
                  CustomIconButton(
                    onPressed: () {},
                    icon: Icons.call,
                    iconColor: Colors.white,
                  ),
                  CustomIconButton(
                    onPressed: () {},
                    icon: Icons.more_vert,
                    iconColor: Colors.white,
                  ),
                ]
              : [
                  CustomIconButton(
                    onPressed: () {},
                    icon: Icons.more_vert,
                    iconColor: Colors.white,
                  ),
                ],
        ),
        body: Stack(
          children: [
            Image(
              height: double.infinity,
              width: double.infinity,
              image: const AssetImage('assets/images/doodle_bg.png'),
              fit: BoxFit.cover,
              color: context.theme.chatPageDoodleColor,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: StreamBuilder<List<MessageModel>>(
                stream: isGroupChat
                    ? ref
                        .watch(chatControllerProvider)
                        .getAllOneToOneGroupMessage(uid)
                    : ref
                        .watch(chatRepositoryProvider)
                        .getAllOneToOneMessage(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      itemCount: 15,
                      itemBuilder: (_, index) {
                        final random = Random().nextInt(14);
                        return Container(
                          alignment: random.isEven
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          margin: EdgeInsets.only(
                            top: 5,
                            bottom: 5,
                            left: random.isEven ? 150 : 15,
                            right: random.isEven ? 15 : 150,
                          ),
                          child: ClipPath(
                            clipper: UpperNipMessageClipperTwo(
                              random.isEven
                                  ? MessageType.send
                                  : MessageType.receive,
                              nipWidth: 8,
                              nipHeight: 10,
                              bubbleRadius: 12,
                            ),
                            child: Shimmer.fromColors(
                              baseColor: random.isEven
                                  ? context.theme.greyColor!.withOpacity(.3)
                                  : context.theme.greyColor!.withOpacity(.2),
                              highlightColor: random.isEven
                                  ? context.theme.greyColor!.withOpacity(.4)
                                  : context.theme.greyColor!.withOpacity(.3),
                              child: Container(
                                height: 40,
                                width:
                                    170 + double.parse((random * 2).toString()),
                                color: context.theme.greyColor!.withOpacity(.2),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  if (snapshot.hasData) {
                    final messages = snapshot.data!;
                    if (messages.isEmpty) {
                      return const Center(
                          child: Text(
                              'Aucun message à afficher.')); // Aucun message dans SQLite
                    }
                    return PageStorage(
                      bucket: pageStorageBucket,
                      child: ListView.builder(
                        key: const PageStorageKey('chat_page_list'),
                        itemCount: messages.length,
                        shrinkWrap: true,
                        controller: scrollController,
                        itemBuilder: (_, index) {
                          final message = messages[index];
                          final isSender = message.senderId == currentUserId;
                          final key = (index == messages.length - 1)
                              ? lastMessageKey
                              : null;
                          final haveNip =
                              _shouldShowNip(index, messages, message);
                          final isShowDateCard =
                              _shouldShowDateCard(index, messages, message);
                          if (message.receiverId == currentUserId) {
                            ref
                                .read(chatControllerProvider)
                                .updateMessageStatusToRead(
                                  messageId: message.messageId,
                                  senderId: message.senderId,
                                );
                          }
                          return Column(
                            children: [
                              if (index == 0) const YellowCard(),
                              if (isShowDateCard)
                                ShowDateCard(date: message.timeSent),
                              MessageCard(
                                key: key,
                                isSender: isSender,
                                haveNip: haveNip,
                                message: message.textMessage,
                                type: message.type,
                                timeSent: message.timeSent,
                                status: message.status,
                                repliedText: message.repliedMessage,
                                repliedMessageType: message.repliedMessageType,
                                username: message.repliedTo,
                                onLeftSwipe: () {
                                  if (isSender) {
                                    onMessageSwipe(
                                      message.textMessage,
                                      message.senderId ==
                                          FirebaseAuth
                                              .instance.currentUser!.uid,
                                      message.type,
                                      ref,
                                    );
                                  }
                                },
                                onRightSwipe: () {
                                  if (!isSender) {
                                    onMessageSwipe(
                                      message.textMessage,
                                      false,
                                      message.type,
                                      ref,
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading messages',
                        style: TextStyle(
                          color: context.theme.authAppbarTextColor,
                        ),
                      ),
                    );
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        color: context.theme.authAppbarTextColor,
                      ),
                    );
                  }
                },
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ChatTextField(
                receiverId: uid,
                scrollController: scrollController,
                isGroupChat: isGroupChat,
              ),
            ),
            ValueListenableBuilder(
              valueListenable: showScrollToBottomButton,
              builder: (context, showButton, child) {
                return showButton
                    ? Positioned(
                        right: 20,
                        bottom: 70,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CustomIconButton(
                            onPressed: scrollToBottom,
                            icon: Icons.keyboard_double_arrow_down,
                            iconColor: context.theme.greyColor,
                          ),
                        ),
                      )
                    : Container();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowNip(
      int index, List<MessageModel> messages, MessageModel message) {
    return index == 0 ||
        index == messages.length - 1 ||
        message.senderId != messages[index - 1].senderId ||
        message.senderId != messages[index + 1].senderId;
  }

  bool _shouldShowDateCard(
      int index, List<MessageModel> messages, MessageModel message) {
    return index == 0 ||
        (index == messages.length - 1 &&
            message.timeSent.day > messages[index - 1].timeSent.day) ||
        (message.timeSent.day > messages[index - 1].timeSent.day &&
            message.timeSent.day <= messages[index + 1].timeSent.day);
  }
}
