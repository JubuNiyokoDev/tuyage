import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:tuyage/common/enum/message_status.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/models/group.dart';
import 'package:tuyage/common/models/last_message_model.dart';
import 'package:tuyage/common/models/message_model.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/providers/message_reply_provider.dart';
import 'package:tuyage/common/repository/firebase_storage_repository.dart';
import 'package:tuyage/config/database_helper.dart';
import 'package:tuyage/feature/auth/controller/auth_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:tuyage/common/enum/message_type.dart' as myMessageType;

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class ChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  bool isConnected = false;

  ChatRepository({required this.firestore, required this.auth});

  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  void monitorUserConnectivity(WidgetRef ref, BuildContext context) {
    connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) async {
      final uid = auth.currentUser?.uid;
      final authController = ref.read(authControllerProvider);

      bool currentConnection = result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi;

      if (currentConnection != isConnected) {
        isConnected = currentConnection;

        if (!isConnected) {
          print("L'utilisateur est déconnecté");
          if (uid != null) {
            await authController.updateUserPresenceToOffline(uid, context);
          }
        } else {
          print("L'utilisateur est connecté");
          if (uid != null) {
            await updateUserActiveStatus(true);
            await updateUserLastSeen(uid);

            // Appeler la synchronisation des messages ici
            var pendingMessages = await getLocalMessages(auth.currentUser!.uid);
            if (pendingMessages.isNotEmpty) {
              await syncAllMessages();
            }
          }
        }
      }
    });
  }

  Future<void> updateUserLastSeen(String uid) async {
    await firestore.collection('users').doc(uid).update({
      'lastSeen': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  Future<void> updateUserActiveStatus(bool isActive) async {
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      await firestore.collection('users').doc(currentUser.uid).update({
        'active': isActive,
        'lastSeen': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    } else {
      print("L'utilisateur est null, impossible de mettre à jour son statut.");
    }
  }

  void monitorReceiverStatus(String receiverId) {
    final receiverDocRef = firestore.collection('users').doc(receiverId);

    receiverDocRef.snapshots().listen((docSnapshot) async {
      if (docSnapshot.exists) {
        final bool isOnline = docSnapshot.data()?['active'] ?? false;
        if (isOnline) {
          await _updatePendingMessages(receiverId);
        }
      }
    });
  }

  Future<void> _updatePendingMessages(String receiverId) async {
    final pendingMessagesQuery = await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .where(
          'status',
          isEqualTo: _getStringFromStatus(MessageStatus.pending),
        )
        .get();

    for (var doc in pendingMessagesQuery.docs) {
      final messageId = doc.id;
      await updateMessageStatus(
        messageId: messageId,
        status: MessageStatus.delivered,
        receiverId: receiverId,
      );
      await updateMessageStatusInSQLite(
        messageId,
        MessageStatus.delivered,
      );
    }
  }

  Future<bool> isConnectedToNetwork() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      for (var result in connectivityResult) {
        if (result == ConnectivityResult.mobile) {
          print('Connected via Mobile');
          return true;
        } else if (result == ConnectivityResult.wifi) {
          print('Connected via WiFi');
          return true;
        }
      }
      print('Not connected to mobile or wifi');
      return false;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  Stream<List<MessageModel>> getAllOneToOneMessage(String receiverId) async* {
    final isConnected = await isConnectedToNetwork();

    if (isConnected) {
      print('Récupération des messages depuis Firestore :');
      yield* firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverId)
          .collection('messages')
          .orderBy('timeSent', descending: false)
          .snapshots()
          .map((snapshot) {
        // Vérifier s'il y a des documents dans la collection
        if (snapshot.docs.isEmpty) {
          print('Aucun message trouvé pour ce destinataire.');
          return <MessageModel>[]; // Retourner une liste vide si aucun message
        }

        final messages = snapshot.docs.map((doc) {
          var data = doc.data();

          print('Message ID: ${doc.id}, Status: ${data['status']}');

          return MessageModel.fromMap({
            'messageId': doc.id,
            'senderId': data['senderId'],
            'receiverId': data['receiverId'],
            'textMessage': data['textMessage'],
            'type': data['type'],
            'timeSent': data['timeSent'],
            'status': MessageStatus.values.firstWhere(
                (e) => e.toString() == data['status'],
                orElse: () => MessageStatus.pending),
            'repliedMessage': data['repliedMessage'] ?? '',
            'repliedTo': data['repliedTo'] ?? '',
            'repliedMessageType': data['repliedMessageType'] ?? '',
          });
        }).toList();

        _syncMessagesWithSQLite(
            messages); // Appel de la fonction pour synchroniser avec SQLite

        return messages;
      }).handleError((error) {
        print(
            'Erreur lors de la récupération des messages depuis Firestore: $error');
      });
    } else {
      print('Récupération des messages depuis SQLITE :');
      final localMessages = await getLocalMessages(receiverId);
      yield localMessages;
    }
  }

// Fonction pour synchroniser les messages avec SQLite
  Future<void> _syncMessagesWithSQLite(List<MessageModel> messages) async {
    for (var message in messages) {
      // Vérifier si le message existe localement
      final existsLocally = await messageExistsLocally(message.messageId);

      if (!existsLocally) {
        // Si le message n'existe pas, l'insérer dans SQLite
        await saveMessageLocally(message);
        print('Message sauvegardé dans SQLite : ${message.messageId}');
      } else {
        // Si le message existe, vérifier et mettre à jour son statut si nécessaire
        await updateMessageStatusInSQLite(message.messageId, message.status);
        print(
            'Statut du message mis à jour dans SQLite : ${message.messageId}');
      }
    }
  }

  Stream<List<MessageModel>> getAllOneToOneGroupMessages(String groupId) {
    return firestore
        .collection('groups')
        .doc(groupId)
        .collection('chats')
        .orderBy('timeSent', descending: false)
        .snapshots()
        .map((event) {
      return event.docs
          .map((message) => MessageModel.fromMap(message.data()))
          .toList();
    });
  }

  Stream<List<LastMessageModel>> getAllLastMessageList() {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .orderBy('timeSent', descending: true)
        .snapshots()
        .asyncMap((event) async {
      final uniqueContacts = <String, LastMessageModel>{};

      if (event.docs.isEmpty) {
        return [];
      }

      for (var document in event.docs) {
        final lastMessage = LastMessageModel.fromMap(document.data());
        if (!uniqueContacts.containsKey(lastMessage.contactId)) {
          try {
            final userData = await firestore
                .collection('users')
                .doc(lastMessage.contactId)
                .get();
            if (userData.exists) {
              final user = UserModel.fromMap(userData.data()!);
              uniqueContacts[lastMessage.contactId] = LastMessageModel(
                username: user.username,
                profileImageUrl: user.profileImageUrl,
                contactId: lastMessage.contactId,
                timeSent: lastMessage.timeSent,
                lastMessage: lastMessage.lastMessage,
                email: lastMessage.email,
              );
            }
          } catch (e) {
            print('Erreur lors de la récupération des données utilisateur: $e');
          }
        }
      }
      return uniqueContacts.values.toList();
    });
  }

  Stream<List<Group>> getChatGroups() {
    return firestore
        .collection('groups')
        .orderBy('timeSent', descending: true)
        .snapshots()
        .map((event) {
      List<Group> groups = [];

      for (var document in event.docs) {
        var group = Group.fromMap(document.data());
        if (group.membersUid.contains(auth.currentUser!.uid)) {
          groups.add(group);
        }
      }
      return groups;
    });
  }

  Future<void> updateMessageStatusToRead({
    required String messageId,
    required String senderId,
  }) async {
    try {
      // Références aux documents pour le destinataire (Jubu)
      final receiverDocRef = firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(senderId) // Référence à la conversation avec l'expéditeur
          .collection('messages')
          .doc(messageId);

      // Références aux documents pour l'expéditeur (Janeiro)
      final senderDocRef = firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(auth.currentUser!
              .uid) // Référence à la conversation avec le destinataire
          .collection('messages')
          .doc(messageId);

      // Vérification et mise à jour du statut pour le destinataire
      final receiverDocSnapshot = await receiverDocRef.get();
      if (receiverDocSnapshot.exists &&
          receiverDocSnapshot.data()?['status'] !=
              _getStringFromStatus(MessageStatus.read)) {
        await receiverDocRef
            .update({'status': _getStringFromStatus(MessageStatus.read)});
        print('Changed status to read for receiver doc');
      } else {
        print(
            'No change needed for receiver doc. Current status: ${receiverDocSnapshot.data()?['status']}');
      }

      // Vérification et mise à jour du statut pour l'expéditeur
      final senderDocSnapshot = await senderDocRef.get();
      if (senderDocSnapshot.exists &&
          senderDocSnapshot.data()?['status'] !=
              _getStringFromStatus(MessageStatus.read)) {
        await senderDocRef
            .update({'status': _getStringFromStatus(MessageStatus.read)});
        print('Changed status to read for sender doc');
      } else {
        print(
            'No change needed for sender doc. Current status: ${senderDocSnapshot.data()?['status']}');
      }

      // Mise à jour dans SQLite uniquement si nécessaire
      await updateMessageStatusInSQLite(
        messageId,
        MessageStatus.read,
      );
    } catch (e) {
      print('Erreur lors de la mise à jour du statut du message : $e');
    }
  }

  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
    required String receiverId,
  }) async {
    try {
      final senderDocRef = firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverId)
          .collection('messages')
          .doc(messageId);

      final receiverDocRef = firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId);

      // Vérifier et mettre à jour Firestore pour l'expéditeur
      final senderDocSnapshot = await senderDocRef.get();
      if (senderDocSnapshot.exists &&
          senderDocSnapshot.data()?['status'] != _getStringFromStatus(status)) {
        await senderDocRef.update({'status': _getStringFromStatus(status)});
        print(
            'Changed status ${senderDocSnapshot.data()?['status']} for sender doc to ${_getStringFromStatus(status)}');
      } else {
        print(
            'Not Changed status ${senderDocSnapshot.data()?['status']} for receiver doc to ${_getStringFromStatus(status)} et voici le document trouve ${senderDocSnapshot.exists}');
      }

      // Vérifier et mettre à jour Firestore pour le destinataire
      final receiverDocSnapshot = await receiverDocRef.get();
      if (receiverDocSnapshot.exists &&
          receiverDocSnapshot.data()?['status'] !=
              _getStringFromStatus(status)) {
        await receiverDocRef.update({'status': _getStringFromStatus(status)});
        print(
            'Changed status ${receiverDocSnapshot.data()?['status']} for receiver doc to ${_getStringFromStatus(status)}');
      } else {
        print(
            'Not Changed status ${receiverDocSnapshot.data()?['status']} for receiver doc to ${_getStringFromStatus(status)} et voici le document trouve ${receiverDocSnapshot.exists}');
      }

      // Mise à jour dans sqlite uniquement si nécessaire
      await updateMessageStatusInSQLite(messageId, status);
    } catch (e) {
      print('Erreur lors de la mise à jour du statut du message : $e');
    }
  }

  Future<void> syncMessages(String receiverId) async {
    try {
      // Récupération des messages de Firestore
      final firestoreMessagesSnapshot = await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverId)
          .collection('messages')
          .get();

      if (firestoreMessagesSnapshot.docs.isEmpty) {
        print('Aucun message trouvé dans Firestore pour ce destinataire.');
        return;
      }

      final firestoreMessageIds =
          firestoreMessagesSnapshot.docs.map((doc) => doc.id).toSet();

      // Récupération des messages locaux
      final localMessages = await getLocalMessages(auth.currentUser!.uid);

      if (localMessages.isEmpty) {
        print('Aucun message trouvé localement.');
      }

      // Synchronisation des messages
      for (var localMessage in localMessages) {
        if (localMessage.receiverId == receiverId) {
          // Si le message n'existe pas dans Firestore, l'envoyer
          if (!firestoreMessageIds.contains(localMessage.messageId)) {
            await saveToMessageCollection(
              receiverId: receiverId,
              textMessage: localMessage.textMessage,
              timeSent: localMessage.timeSent,
              textMessageId: localMessage.messageId,
              senderUsername: localMessage.senderId,
              receiverUsername: localMessage.receiverId,
              messageType: localMessage.type,
              messageReply: null,
              isGroupChat: false,
            );
          }
        }
      }

      print("Synchronisation des messages terminée.");
    } catch (e) {
      print('Erreur lors de la synchronisation des messages : $e');
    }
  }

// Vérifier si un message existe déjà localement
  Future<bool> messageExistsLocally(String messageId) async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      'messages',
      where: 'messageId  = ?',
      whereArgs: [messageId],
    );

    return result.isNotEmpty;
  }

  void sendTextMessage({
    required BuildContext context,
    required String textMessage,
    required String receiverId,
    required UserModel senderData,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      final timeSent = DateTime.now();
      UserModel? receiverData;

      // Récupérer les données du destinataire si ce n'est pas un chat de groupe
      if (!isGroupChat) {
        if (receiverId.isEmpty) {
          print("Le receiverId est vide.");
          return;
        }
        print("Le receiverId n'est pas vide.");
        final receiverDataMap =
            await firestore.collection('users').doc(receiverId).get();
        // Vérifie que les données existent avant de créer l'utilisateur
        if (receiverDataMap.exists) {
          receiverData = UserModel.fromMap(receiverDataMap.data()!);
        } else {
          // Gestion d'erreur si l'utilisateur n'existe pas
          print("L'utilisateur avec l'ID $receiverId n'existe pas.");
          return;
        }
      }

      // Génération de l'ID du message unique
      final textMessageId = const Uuid().v1();

      print('Sender ID: ${senderData.uid}');
      print('Receiver ID: $receiverId');
      print('Text Message: $textMessage');
      print('Replied Message: ${messageReply?.message}');
      print(
          'Replied To: ${messageReply == null ? '' : messageReply.isMe ? (senderData.username ?? 'Utilisateur inconnu') : (receiverData?.username ?? 'Utilisateur inconnu')}');
      print('Receiver Username: ${receiverData?.username}');

      // Création du modèle de message local
      final localMessage = MessageModel(
        senderId: senderData.uid,
        receiverId: receiverId,
        textMessage: textMessage,
        type: myMessageType.MessageType.text,
        timeSent: timeSent,
        messageId: textMessageId,
        status: MessageStatus.pending,
        repliedMessage: messageReply?.message ?? '',
        repliedTo: messageReply == null
            ? ''
            : messageReply.isMe
                ? senderData.username
                : receiverData?.username ?? '',
        repliedMessageType:
            messageReply?.messageType ?? myMessageType.MessageType.text,
      );

      // Vérifier si le message n'a pas déjà été sauvegardé localement
      if (!await messageExistsLocally(textMessageId)) {
        await saveMessageLocally(localMessage);
      } else {
        print("Le message ${textMessageId} existe déjà localement.");
        return; // Arrêter l'exécution si le message existe déjà
      }

      // Vérifier la connectivité réseau
      bool isConnected = await isConnectedToNetwork();

      if (isConnected) {
        // await syncMessages(receiverId);
        await saveToMessageCollection(
          receiverId: receiverId,
          textMessage: textMessage,
          timeSent: timeSent,
          textMessageId: textMessageId,
          senderUsername: senderData.username,
          receiverUsername: receiverData?.username ?? 'Utilisateur inconnu',
          messageType: myMessageType.MessageType.text,
          messageReply: messageReply,
          isGroupChat: isGroupChat,
        );
        saveAsLastMessage(
          senderUserData: senderData,
          receiverUserData: receiverData,
          lastMessage: textMessage,
          timeSent: timeSent,
          receiverId: receiverId,
          isGroupChat: isGroupChat,
        );

        // Mise à jour du statut une fois envoyé
        await updateMessageStatus(
          messageId: textMessageId,
          status: MessageStatus.sent,
          receiverId: receiverId,
        );

        // Mettre à jour sqlite une fois le message envoyé
        await updateMessageStatusInSQLite(textMessageId, MessageStatus.sent);
      } else {
        print(
            "Message sauvegardé localement. Il sera envoyé lorsque la connexion sera rétablie.");
      }
    } catch (e) {
      if (context.mounted) {
        print('pour sendtext message on a:  ${e.toString()}');
        showAlertDialog(
            context: context,
            message: 'pour sendtext message on a:  ${e.toString()}');
      }
    }
  }

  Future<void> updateMessageStatusInSQLite(
      String messageId, MessageStatus newStatus) async {
    await DatabaseHelper().updateMessageStatus(messageId, newStatus.toString());
  }

  saveToMessageCollection({
    required String receiverId,
    required String textMessage,
    required DateTime timeSent,
    required String textMessageId,
    required String senderUsername,
    required String? receiverUsername,
    required myMessageType.MessageType messageType,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    final message = MessageModel(
      senderId: auth.currentUser!.uid,
      receiverId: receiverId,
      textMessage: textMessage,
      type: messageType,
      timeSent: timeSent,
      messageId: textMessageId,
      status: MessageStatus.pending,
      repliedMessage: messageReply == null ? '' : messageReply.message,
      repliedTo: messageReply == null
          ? ''
          : messageReply.isMe
              ? senderUsername
              : receiverUsername ?? '',
      repliedMessageType: messageReply == null
          ? myMessageType.MessageType.text
          : messageReply.messageType,
    );

    // Log pour vérifier les chemins
    print('Receiver ID: $receiverId');
    print('Sender ID: ${auth.currentUser!.uid}');
    print('Message to save: ${message.toMap()}');

    if (isGroupChat) {
      await firestore
          .collection('groups')
          .doc(receiverId) // Assure-toi que receiverId est valide
          .collection('chats')
          .doc(textMessageId) // Vérifie que textMessageId est aussi valide
          .set(message.toMap());
    } else {
      // Vérification pour l'expéditeur
      if (auth.currentUser!.uid.isNotEmpty && receiverId.isNotEmpty) {
        await Future.wait([
          firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(receiverId)
              .collection('messages')
              .doc(textMessageId)
              .set(
                message.toMap(),
              ),
          firestore
              .collection('users')
              .doc(receiverId)
              .collection('chats')
              .doc(auth.currentUser!.uid)
              .collection('messages')
              .doc(textMessageId)
              .set(
                message.toMap(),
              ),
        ]);
      } else {
        print(
            "Sender ID ou Receiver ID est vide lors de l'enregistrement du message.");
      }
    }
  }

  saveAsLastMessage({
    required UserModel senderUserData,
    required UserModel? receiverUserData,
    required String lastMessage,
    required DateTime timeSent,
    required String receiverId,
    required bool isGroupChat,
  }) async {
    if (isGroupChat) {
      await firestore.collection('groups').doc(receiverId).update({
        'lastMessage': lastMessage,
        'timeSent': timeSent.millisecondsSinceEpoch,
      });
    } else {
      final receiverLastMessage = LastMessageModel(
        username: senderUserData.username,
        profileImageUrl: senderUserData.profileImageUrl,
        contactId: senderUserData.uid,
        timeSent: timeSent,
        lastMessage: lastMessage,
        email: senderUserData.email,
      );

      await firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .set(
            receiverLastMessage.toMap(),
          );

      final senderLastMessage = LastMessageModel(
        username: receiverUserData!.username,
        profileImageUrl: receiverUserData.profileImageUrl,
        contactId: receiverUserData.uid,
        timeSent: timeSent,
        lastMessage: lastMessage,
        email: receiverUserData.email,
      );

      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverId)
          .set(
            senderLastMessage.toMap(),
          );
    }
  }

  void sendFileMessage({
    required var file,
    required BuildContext context,
    required String receiverId,
    required UserModel senderData,
    required Ref ref,
    required myMessageType.MessageType messageType,
    required MessageReply? messageRelpy,
    required bool isGroupChat,
  }) async {
    try {
      final timeSent = DateTime.now();
      final messageId = const Uuid().v1();
      UserModel? receverUserData;

      final imageUrl =
          await ref.read(firebaseStorageRepositoryProvider).storeFileToFirebase(
                'chats/${messageType.type}/${senderData.uid}/$receiverId/$messageId',
                file,
              );
      if (!isGroupChat) {
        final receiverDataMap =
            await firestore.collection('users').doc(receiverId).get();
        receverUserData = UserModel.fromMap(receiverDataMap.data()!);
      }

      String lastMessage;

      switch (messageType) {
        case myMessageType.MessageType.image:
          lastMessage = 'Photo';
          break;
        case myMessageType.MessageType.audio:
          lastMessage = 'Voice';
          break;
        case myMessageType.MessageType.video:
          lastMessage = 'Video';
          break;
        case myMessageType.MessageType.gif:
          lastMessage = 'GIF';
          break;
        default:
          lastMessage = '📦 GIF';
          break;
      }

      saveToMessageCollection(
        receiverId: receiverId,
        textMessage: imageUrl,
        timeSent: timeSent,
        textMessageId: messageId,
        senderUsername: senderData.username,
        receiverUsername: receverUserData?.username,
        messageType: messageType,
        messageReply: messageRelpy,
        isGroupChat: isGroupChat,
      );

      saveAsLastMessage(
        senderUserData: senderData,
        receiverUserData: receverUserData,
        lastMessage: lastMessage,
        timeSent: timeSent,
        receiverId: receiverId,
        isGroupChat: isGroupChat,
      );
    } catch (e) {
      if (context.mounted) {
        showAlertDialog(context: context, message: e.toString());
      }
    }
  }

  void sendGIFMessage({
    required BuildContext context,
    required String gifUrl,
    required String receiverId,
    required UserModel senderData,
    required MessageReply? messageRelpy,
    required bool isGroupChat,
  }) async {
    try {
      final timeSent = DateTime.now();
      UserModel? receiverData;
      if (!isGroupChat) {
        final receiverDataMap =
            await firestore.collection('users').doc(receiverId).get();
        receiverData = UserModel.fromMap(receiverDataMap.data()!);
      }
      final textMessageId = const Uuid().v1();

      saveToMessageCollection(
        receiverId: receiverId,
        textMessage: gifUrl,
        timeSent: timeSent,
        textMessageId: textMessageId,
        senderUsername: senderData.username,
        receiverUsername: receiverData?.username,
        messageType: myMessageType.MessageType.gif,
        messageReply: messageRelpy,
        isGroupChat: isGroupChat,
      );

      saveAsLastMessage(
        senderUserData: senderData,
        receiverUserData: receiverData,
        lastMessage: gifUrl,
        timeSent: timeSent,
        receiverId: receiverId,
        isGroupChat: isGroupChat,
      );
    } catch (e) {
      if (context.mounted) {
        showAlertDialog(context: context, message: e.toString());
      }
    }
  }

  Future<void> syncAllMessages() async {
    // Récupérer tous les IDs des contacts avec qui l'utilisateur a des conversations
    final chatsSnapshot = await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .get();

    for (var doc in chatsSnapshot.docs) {
      String receiverId = doc.id;
      await syncMessages(receiverId);
    }
  }

  Future<void> deleteLocalMessage(String messageId) async {
    await DatabaseHelper().deleteMessage(messageId);
  }

  Future<void> saveMessageLocally(MessageModel message) async {
    final messageMap = message.toMap();
    await DatabaseHelper().insertMessage(messageMap);
  }

  Future<List<MessageModel>> getLocalMessages(String receiverId) async {
    final messages = await DatabaseHelper().getMessages(receiverId);

    if (messages.isEmpty) {
      print('Aucun message trouvé localement pour ce destinataire.');
    }

    return messages
        .map((messageMap) => MessageModel.fromMap(messageMap))
        .toList();
  }

  // Convertir un MessageStatus en chaîne courte
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
}
