import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/enum/message_status.dart';
import 'package:tuyage/common/models/group.dart';
import 'package:tuyage/common/models/last_message_model.dart';
import 'package:tuyage/common/models/message_model.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/providers/message_reply_provider.dart';
import 'package:tuyage/feature/auth/controller/auth_controller.dart';
import 'package:tuyage/feature/chat/repository/chat_repository.dart';
import 'package:tuyage/common/enum/message_type.dart' as myMessageType;

final chatControllerProvider = Provider((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return ChatController(chatRepository: chatRepository, ref: ref);
});

class ChatController {
  final ChatRepository chatRepository;
  final ProviderRef ref;

  ChatController({required this.chatRepository, required this.ref});
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  void monitorNetworkStatus(BuildContext context, bool isGroupChat) async {
    if (connectivitySubscription != null) {
      await connectivitySubscription!.cancel();
      print("nothing to do because $connectivitySubscription");
    }

    // Vérifie la connectivité initiale
    final connectivityResult = await Connectivity().checkConnectivity();
    _handleConnectivityChange(connectivityResult, context, isGroupChat);

    // Surveille les changements de connectivité
    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _handleConnectivityChange(result, context, isGroupChat);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> connectivityResult,
      BuildContext context, bool isGroupChat) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      // Utilisez la fonction isConnectedToNetwork pour déterminer la connectivité
      bool isConnected =
          await ref.read(chatRepositoryProvider).isConnectedToNetwork();

      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'active': isConnected,
        'lastSeen': isConnected ? null : DateTime.now().millisecondsSinceEpoch,
      });

      if (isConnected) {
        // Relance les messages en attente si l'utilisateur est reconnecté
        // resendPendingMessages(context, isGroupChat);
        ref.read(chatRepositoryProvider).syncAllMessages();
         UserModel? receiverData = await chatRepository.getReceiverData(uid);

        // Appeler _syncPendingMessages avec les bons paramètres
        await chatRepository.syncPendingMessages(uid, receiverData, isGroupChat);
      } else {
        // Mise à jour pour passer "offline" après un délai
        Timer(const Duration(minutes: 5), () {
          FirebaseFirestore.instance.collection('users').doc(uid).update({
            'active': false,
            'lastSeen': DateTime.now().millisecondsSinceEpoch,
          });
        });
      }
    }
  }

 

  Future<void> sendFileMessage({
    required BuildContext context,
    required var file,
    String? receiverId,
    required myMessageType.MessageType messageType,
    required bool isGroupChat,
  }) async {
    final messageReply = ref.read(messageReplyProvider);
    ref.read(userInfoAuthProvider).whenData((senderData) {
      return chatRepository.sendFileMessage(
        file: file,
        context: context,
        receiverId: receiverId!,
        senderData: senderData!,
        ref: ref,
        messageType: messageType,
        messageRelpy: messageReply,
        isGroupChat: isGroupChat,
      );
    });
    ref.read(messageReplyProvider.state).update((state) => null);
  }

  Future<void> sendTextMessage({
    required BuildContext context,
    required String textMessage,
    required String receiverId,
    required bool isGroupChat,
  }) async {
    final messageReply = ref.read(messageReplyProvider);

    // Utiliser AsyncValue pour obtenir les données utilisateur
    final userInfo = ref.read(userInfoAuthProvider);

    // Vérifie si userInfo contient une valeur valide
    userInfo.when(
      data: (value) {
        // Appelle sendTextMessage sans await
        chatRepository.sendTextMessage(
          context: context,
          textMessage: textMessage,
          receiverId: receiverId,
          senderData: value!,
          messageReply: messageReply,
          isGroupChat: isGroupChat,
        );

        // Réinitialise le messageReply après l'envoi
        ref.read(messageReplyProvider.state).update((state) => null);
      },
      loading: () {
        // Gérer le cas où les données sont encore en chargement
        print('Chargement des données utilisateur...');
      },
      error: (error, stack) {
        // Gérer les erreurs ici
        print('Erreur lors de la récupération des données utilisateur: $error');
      },
    );
  }

  Stream<List<MessageModel>> getMessages(String receiverId) {
    return chatRepository.getAllOneToOneMessage(receiverId);
  }

  Stream<List<MessageModel>> getAllOneToOneGroupMessage(String groupId) {
    return chatRepository.getAllOneToOneGroupMessages(groupId);
  }

  Stream<List<LastMessageModel>> getAllLastMessageList() {
    return chatRepository.getAllLastMessageList();
  }

  Stream<List<Group>> chatGroups() {
    return chatRepository.getChatGroups();
  }

  void SendGIFMessage(
    BuildContext context,
    String gifUrl,
    String receiverId,
    bool isGroupChat,
  ) {
    int gifUrlPartIndex = gifUrl.lastIndexOf('-') + 1;
    String gifUrlPart = gifUrl.substring(gifUrlPartIndex);
    String newgifUrl = 'https://i.giphy.com/media/$gifUrlPart/200.gif';
    final messageReply = ref.read(messageReplyProvider);
    ref.read(userInfoAuthProvider).whenData(
          (value) => chatRepository.sendGIFMessage(
            context: context,
            gifUrl: newgifUrl,
            receiverId: receiverId,
            senderData: value!,
            messageRelpy: messageReply,
            isGroupChat: isGroupChat,
          ),
        );
    ref.read(messageReplyProvider.state).update((state) => null);
  }

  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
    required String receiverId,
  }) async {
    await chatRepository.updateMessageStatus(
      messageId: messageId,
      status: status,
      receiverId: receiverId,
    );
  }

  Future<void> updateMessageStatusToRead({
    required String messageId,
    required String senderId,
  }) async {
    await chatRepository.updateMessageStatusToRead(
      messageId: messageId,
      senderId: senderId,
    );
  }
}
