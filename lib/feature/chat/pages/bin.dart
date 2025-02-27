// import 'dart:math';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:custom_clippers/custom_clippers.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:tuyage/common/enum/message_status.dart';
// import 'package:tuyage/common/extension/custom_theme_extension.dart';
// import 'package:tuyage/common/helper/last_seen_message.dart';
// import 'package:tuyage/common/models/message_model.dart';
// import 'package:tuyage/common/models/user_model.dart';
// import 'package:tuyage/common/providers/message_reply_provider.dart';
// import 'package:tuyage/common/routes/routes.dart';
// import 'package:tuyage/common/widgets/custom_icon_button.dart';
// import 'package:tuyage/feature/auth/controller/auth_controller.dart';
// import 'package:tuyage/feature/call/controller/call_controller.dart';
// import 'package:tuyage/feature/call/screens/call_pickup_screen.dart';
// import 'package:tuyage/feature/chat/controller/chat_controller.dart';
// import 'package:tuyage/feature/chat/repository/chat_repository.dart';
// import 'package:tuyage/feature/chat/widgets/chat_text_field.dart';
// import 'package:tuyage/feature/chat/widgets/message_card.dart';
// import 'package:tuyage/feature/chat/widgets/show_date_card.dart';
// import 'package:tuyage/feature/chat/widgets/yellow_card.dart';
// import 'package:tuyage/common/enum/message_type.dart' as myMessageType;

// final pageStorageBucket = PageStorageBucket();

// class ChatPage extends ConsumerStatefulWidget {
//   ChatPage({
//     super.key,
//     required this.name,
//     required this.uid,
//     required this.isGroupChat,
//     required this.profileImage,
//     required this.lastSeen,
//     required this.user,
//   });

//   final String name;
//   final String uid;
//   final bool isGroupChat;
//   final String profileImage;
//   final int? lastSeen;
//   final UserModel? user;
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }

// class _ChatPageState extends ConsumerState<ChatPage> {
//   final ScrollController scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     scrollController.addListener(_scrollListener);
//   }

//   @override
//   void dispose() {
//     scrollController.removeListener(_scrollListener);
//     scrollController.dispose();
//     super.dispose();
//   }

//   void _scrollListener() {
//     if (!scrollController.hasClients) return;

//     final offset = scrollController.offset;
//     final viewportHeight = scrollController.position.viewportDimension;
//     final height = scrollController.position.maxScrollExtent;

//     if (offset >= height - viewportHeight) {
//       if (!widget.isGroupChat) {
//         final currentUserId = FirebaseAuth.instance.currentUser!.uid;
//         ref
//             .read(chatControllerProvider)
//             .getMessages(widget.uid)
//             .listen((messages) {
//           for (final message in messages) {
//             if (message.senderId != currentUserId &&
//                 message.status != MessageStatus.read) {
//               ref.read(chatControllerProvider).updateMessageStatusToRead(
//                     messageId: message.messageId,
//                     senderId: message.senderId,
//                   );
//             }
//           }
//         });
//       }
//     }
//   }

//   void scrollToBottom() {
//     scrollController.animateTo(
//       scrollController.position.maxScrollExtent,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeOut,
//     );
//   }

//   void makeCall(WidgetRef ref, BuildContext context) {
//     ref.read(callControllerProvider).makeCall(
//           context,
//           widget.name,
//           widget.uid,
//           widget.profileImage,
//           widget.isGroupChat,
//         );
//   }

//   void onMessageSwipe(String message, bool isMe,
//       myMessageType.MessageType messageType, WidgetRef ref) {
//     ref.read(messageReplyProvider.state).update(
//           (state) => MessageReply(
//             message,
//             isMe,
//             messageType,
//           ),
//         );
//   }

//   @override
//   Widget build(BuildContext context) {
//     var firebaseUser = FirebaseAuth.instance.currentUser;
//     final displayUsername =
//         widget.uid == firebaseUser!.uid ? '${widget.name} (You)' : widget.name;
//     final currentUserId = firebaseUser.uid;

//     // scrollController.addListener(() {
//     //   if (!scrollController.hasClients) return;

//     //   final offset = scrollController.offset;
//     //   final viewportHeight = scrollController.position.viewportDimension;
//     //   final height = scrollController.position.maxScrollExtent;

//     //   if (offset >= height - viewportHeight) {
//     //     if (!widget.isGroupChat) {
//     //       ref
//     //           .read(chatControllerProvider)
//     //           .getMessages(widget.uid)
//     //           .listen((messages) {
//     //         for (final message in messages) {
//     //           if (message.senderId != currentUserId &&
//     //               message.status != MessageStatus.read) {
//     //             ref.read(chatControllerProvider).updateMessageStatusToRead(
//     //                   messageId: message.messageId,
//     //                   senderId: message.senderId,
//     //                 );
//     //           }
//     //         }
//     //       });
//     //     }
//     //   }
//     // });

//     return CallPickupScreen(
//       scaffold: Scaffold(
//         backgroundColor: context.theme.chatPageBgColor,
//         appBar: AppBar(
//           leading: InkWell(
//             onTap: () => Navigator.of(context).pop(),
//             borderRadius: BorderRadius.circular(20),
//             child: Row(
//               children: [
//                 const Icon(Icons.arrow_back),
//                 Hero(
//                   tag: 'profile',
//                   child: Container(
//                     width: 32,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       image: DecorationImage(
//                         image: CachedNetworkImageProvider(widget.profileImage),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           title: InkWell(
//             onTap: () async {
//               if (widget.isGroupChat) {
//                 Navigator.pushNamed(
//                   context,
//                   Routes.groupProfile,
//                   arguments: {
//                     'groupName': widget.name,
//                     'uid': widget.uid,
//                   },
//                 );
//               } else {
//                 Navigator.pushNamed(
//                   context,
//                   Routes.profile,
//                   arguments: widget.user,
//                 );
//               }
//             },
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   widget.isGroupChat
//                       ? Text(
//                           widget.name,
//                         )
//                       : Text(
//                           displayUsername.isNotEmpty
//                               ? displayUsername
//                               : 'Loading...',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             color: Colors.white,
//                           ),
//                         ),
//                   const SizedBox(height: 3),
//                   !widget.isGroupChat
//                       ? StreamBuilder<ConnectivityResult>(
//                           stream: ref
//                               .read(authControllerProvider)
//                               .getUserPresenceStatus(uid: widget.uid),
//                           builder: (_, snapshot) {
//                             if (snapshot.connectionState !=
//                                 ConnectionState.active) {
//                               final getlastSeen =
//                                   lastSeenMessage(widget.lastSeen ?? 0);
//                               widget.uid == currentUserId
//                                   ? 'Wiyandikire wewe nyene'
//                                   : getlastSeen;

//                               return Text(
//                                 "haciye $getlastSeen",
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.white,
//                                 ),
//                               );
//                             }

//                             if (snapshot.hasError) {
//                               print('Error: ${snapshot.error}');
//                               return const Text(
//                                 'Error',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.red,
//                                 ),
//                               );
//                             }

//                             if (!snapshot.hasData) {
//                               return const Text(
//                                 'No data',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.white,
//                                 ),
//                               );
//                             }

//                             final ConnectivityResult connectivityResult =
//                                 snapshot.data!;

//                             final bool isConnected = connectivityResult ==
//                                     ConnectivityResult.mobile ||
//                                 connectivityResult == ConnectivityResult.wifi;

//                             final lastMessage =
//                                 lastSeenMessage(widget.lastSeen ?? 0);
//                             final displayLasteSeen = widget.uid == currentUserId
//                                 ? 'Wiyandikire wewe nyene'
//                                 : "haciye $lastMessage";

//                             return Text(
//                               isConnected ? 'online' : displayLasteSeen,
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.white,
//                               ),
//                             );
//                           },
//                         )
//                       : Container(),
//                 ],
//               ),
//             ),
//           ),
//           actions: currentUserId != widget.uid
//               ? [
//                   CustomIconButton(
//                     onPressed: () => makeCall(ref, context),
//                     icon: Icons.video_call,
//                     iconColor: Colors.white,
//                   ),
//                   CustomIconButton(
//                     onPressed: () {},
//                     icon: Icons.call,
//                     iconColor: Colors.white,
//                   ),
//                   CustomIconButton(
//                     onPressed: () {},
//                     icon: Icons.more_vert,
//                     iconColor: Colors.white,
//                   ),
//                 ]
//               : [
//                   CustomIconButton(
//                     onPressed: () {},
//                     icon: Icons.more_vert,
//                     iconColor: Colors.white,
//                   ),
//                 ],
//         ),
//         body: Stack(
//           children: [
//             Image(
//               height: double.infinity,
//               width: double.infinity,
//               image: const AssetImage('assets/images/doodle_bg.png'),
//               fit: BoxFit.cover,
//               color: context.theme.chatPageDoodleColor,
//             ),
//             Padding(
//               padding: const EdgeInsets.only(bottom: 50),
//               child: StreamBuilder<List<MessageModel>>(
//                 stream: widget.isGroupChat
//                     ? ref
//                         .watch(chatControllerProvider)
//                         .getAllOneToOneGroupMessage(widget.uid)
//                     : ref
//                         .watch(chatRepositoryProvider)
//                         .getAllOneToOneMessage(widget.uid),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return ListView.builder(
//                       itemCount: 15,
//                       itemBuilder: (_, index) {
//                         final random = Random().nextInt(14);
//                         return Container(
//                           alignment: random.isEven
//                               ? Alignment.centerRight
//                               : Alignment.centerLeft,
//                           margin: EdgeInsets.only(
//                             top: 5,
//                             bottom: 5,
//                             left: random.isEven ? 150 : 15,
//                             right: random.isEven ? 15 : 150,
//                           ),
//                           child: ClipPath(
//                             clipper: UpperNipMessageClipperTwo(
//                               random.isEven
//                                   ? MessageType.send
//                                   : MessageType.receive,
//                               nipWidth: 8,
//                               nipHeight: 10,
//                               bubbleRadius: 12,
//                             ),
//                             child: Shimmer.fromColors(
//                               baseColor: random.isEven
//                                   ? context.theme.greyColor!.withOpacity(.3)
//                                   : context.theme.greyColor!.withOpacity(.2),
//                               highlightColor: random.isEven
//                                   ? context.theme.greyColor!.withOpacity(.4)
//                                   : context.theme.greyColor!.withOpacity(.3),
//                               child: Container(
//                                 height: 40,
//                                 width:
//                                     170 + double.parse((random * 2).toString()),
//                                 color: context.theme.greyColor!.withOpacity(.2),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   }

//                   if (snapshot.hasData) {
//                     final messages = snapshot.data!;
//                     if (messages.isEmpty) {
//                       return const Center(
//                           child: Text(
//                               'Aucun message à afficher.')); // Aucun message dans SQLite
//                     }
//                     return PageStorage(
//                       bucket: pageStorageBucket,
//                       child: ListView.builder(
//                         key: const PageStorageKey('chat_page_list'),
//                         itemCount: messages.length,
//                         shrinkWrap: true,
//                         controller: scrollController,
//                         itemBuilder: (_, index) {
//                           final message = messages[index];
//                           final isSender = message.senderId == currentUserId;
//                           final haveNip =
//                               _shouldShowNip(index, messages, message);
//                           final isShowDateCard =
//                               _shouldShowDateCard(index, messages, message);
//                           if (message.receiverId == currentUserId) {
//                             ref
//                                 .read(chatControllerProvider)
//                                 .updateMessageStatusToRead(
//                                   messageId: message.messageId,
//                                   senderId: message.senderId,
//                                 );
//                           }
//                           return Column(
//                             children: [
//                               if (index == 0) const YellowCard(),
//                               if (isShowDateCard)
//                                 ShowDateCard(date: message.timeSent),
//                               MessageCard(
//                                 isSender: isSender,
//                                 haveNip: haveNip,
//                                 message: message.textMessage,
//                                 type: message.type,
//                                 timeSent: message.timeSent,
//                                 status: message.status,
//                                 repliedText: message.repliedMessage,
//                                 repliedMessageType: message.repliedMessageType,
//                                 username: message.repliedTo,
//                                 onLeftSwipe: () {
//                                   if (isSender) {
//                                     onMessageSwipe(
//                                       message.textMessage,
//                                       message.senderId ==
//                                           FirebaseAuth
//                                               .instance.currentUser!.uid,
//                                       message.type,
//                                       ref,
//                                     );
//                                   }
//                                 },
//                                 onRightSwipe: () {
//                                   if (!isSender) {
//                                     onMessageSwipe(
//                                       message.textMessage,
//                                       false,
//                                       message.type,
//                                       ref,
//                                     );
//                                   }
//                                 },
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     );
//                   } else if (snapshot.hasError) {
//                     return Center(
//                       child: Text(
//                         'Error loading messages',
//                         style: TextStyle(
//                           color: context.theme.authAppbarTextColor,
//                         ),
//                       ),
//                     );
//                   } else {
//                     return Center(
//                       child: CircularProgressIndicator(
//                         color: context.theme.authAppbarTextColor,
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ),
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: ChatTextField(
//                 receiverId: widget.uid,
//                 scrollController: scrollController,
//                 isGroupChat: widget.isGroupChat,
//               ),
//             ),
//           ],
//         ),
//         floatingActionButton: ValueListenableBuilder(
//           valueListenable: scrollController.position.isScrollingNotifier,
//           builder: (context, isScrolling, child) {
//             if (scrollController.offset > 300 && !isScrolling) {
//               return FloatingActionButton(
//                 onPressed: scrollToBottom,
//                 child: const Icon(Icons.arrow_downward),
//               );
//             }
//             return const SizedBox.shrink();
//           },
//         ),
//       ),
//     );
//   }

//   bool _shouldShowNip(
//       int index, List<MessageModel> messages, MessageModel message) {
//     return index == 0 ||
//         index == messages.length - 1 ||
//         message.senderId != messages[index - 1].senderId ||
//         message.senderId != messages[index + 1].senderId;
//   }

//   bool _shouldShowDateCard(
//       int index, List<MessageModel> messages, MessageModel message) {
//     return index == 0 ||
//         (index == messages.length - 1 &&
//             message.timeSent.day > messages[index - 1].timeSent.day) ||
//         (message.timeSent.day > messages[index - 1].timeSent.day &&
//             message.timeSent.day <= messages[index + 1].timeSent.day);
//   }
// }
