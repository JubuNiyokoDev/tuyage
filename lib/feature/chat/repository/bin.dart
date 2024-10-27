// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:tuyage/common/enum/message_status.dart';
// import 'package:tuyage/common/enum/message_type.dart';
// import 'package:tuyage/common/helper/show_alert_dialog.dart';
// import 'package:tuyage/common/models/last_message_model.dart';
// import 'package:tuyage/common/models/message_model.dart';
// import 'package:tuyage/common/models/user_model.dart';
// import 'package:tuyage/common/repository/firebase_storage_repository.dart';
// import 'package:tuyage/feature/auth/controller/auth_controller.dart';
// import 'package:uuid/uuid.dart';

// final chatRepositoryProvider = Provider((ref) {
//   return ChatRepository(
//     firestore: FirebaseFirestore.instance,
//     auth: FirebaseAuth.instance,
//   );
// });

// class ChatRepository {
//   final FirebaseFirestore firestore;
//   final FirebaseAuth auth;
//   bool ariConneted = false;

//   ChatRepository({required this.firestore, required this.auth});

//   StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

//   void monitorUserConnectivity(WidgetRef ref) {
//     connectivitySubscription = Connectivity()
//         .onConnectivityChanged
//         .listen((List<ConnectivityResult> results) async {
//       final uid = auth.currentUser?.uid;
//       final authController = ref.read(authControllerProvider);

//       // Vérifie si l'utilisateur est connecté à un réseau
//       bool currentConnection = results.any((result) =>
//           result == ConnectivityResult.mobile ||
//           result == ConnectivityResult.wifi);

//       // Mise à jour de l'état de connexion uniquement si nécessaire
//       if (currentConnection != ariConneted) {
//         ariConneted = currentConnection;

//         if (!ariConneted) {
//           print("L'utilisateur est déconnecté");
//           if (uid != null) {
//             await authController.updateUserPresenceToOffline(uid);
//           }
//         } else {
//           print("L'utilisateur est connecté");
//           if (uid != null) {
//             await updateUserActiveStatus(true);
//             await updateUserLastSeen(uid);
//           }
//         }
//       }
//     });
//   }

//   Future<void> updateUserLastSeen(String uid) async {
//     await firestore.collection('users').doc(uid).update({
//       'lastSeen': DateTime.now().millisecondsSinceEpoch.toString(),
//     });
//   }

//   Future<void> updateUserActiveStatus(bool isActive) async {
//     final currentUser = auth.currentUser;
//     if (currentUser != null) {
//       await firestore.collection('users').doc(currentUser.uid).update({
//         'active': isActive,
//         'lastSeen': DateTime.now().millisecondsSinceEpoch.toString(),
//       });
//     } else {
//       print("User est null alors on ne peut pas lui faire online ni offline");
//     }
//   }

//   void monitorConnectivityChanges(String receiverId) {
//     connectivitySubscription = Connectivity().onConnectivityChanged.listen(
//       (List<ConnectivityResult> results) {
//         // Vérifie si l'utilisateur est reconnecté à un réseau
//         if (results.contains(ConnectivityResult.mobile) ||
//             results.contains(ConnectivityResult.wifi)) {
//           // Si connecté, met à jour les messages en attente
//           _updatePendingMessages(receiverId);
//         }
//       },
//     );
//   }

//   void monitorReceiverStatus(String receiverId) {
//     final receiverDocRef = firestore.collection('users').doc(receiverId);

//     receiverDocRef.snapshots().listen((docSnapshot) async {
//       if (docSnapshot.exists) {
//         final bool isOnline = docSnapshot.data()?['active'] ?? false;
//         if (isOnline) {
//           // Si le destinataire est en ligne, mettre à jour les messages en attente
//           await _updatePendingMessages(receiverId);
//         }
//       }
//     });
//   }

//   Future<void> _updatePendingMessages(String receiverId) async {
//     final pendingMessagesQuery = await firestore
//         .collection('users')
//         .doc(auth.currentUser!.uid)
//         .collection('chats')
//         .doc(receiverId)
//         .collection('messages')
//         .where('status', isEqualTo: MessageStatus.pending.toString())
//         .get();

//     for (var doc in pendingMessagesQuery.docs) {
//       final messageId = doc.id;
//       await updateMessageStatus(
//         messageId: messageId,
//         status: MessageStatus.delivered,
//         receiverId: receiverId,
//       );
//     }
//   }

//   Future<bool> isConnected() async {
//     final List<ConnectivityResult> connectivityResults =
//         await Connectivity().onConnectivityChanged.first;

//     // Vérifie si l'utilisateur est connecté via Wi-Fi ou mobile
//     return connectivityResults.any((result) =>
//         result == ConnectivityResult.wifi ||
//         result == ConnectivityResult.mobile);
//   }

//   Future<void> sendFileMessage({
//     required BuildContext context,
//     required var file,
//     required String receiverId,
//     required UserModel senderData,
//     required Ref ref,
//     required MessageType messageType,
//   }) async {
//     try {
//       final timeSent = DateTime.now();
//       final messageId = const Uuid().v1();
//       final isOnline = await isConnected();

//       if (!isOnline) {
//         saveMessageLocally(file, receiverId, senderData, messageType);
//         showAlertDialog(
//             context: context,
//             message: 'Pas de connexion. Le message sera envoyé plus tard.');
//         return;
//       }

//       final fileUrl = await ref
//           .read(firebaseStorageRepositoryProvider)
//           .storeFileToFirebase(
//               'chats/${messageType.type}/${senderData.uid}/$receiverId/$messageId',
//               file);

//       final lastMessage = _getLastMessageByType(messageType);
//       final message = MessageModel(
//         senderId: senderData.uid,
//         receiverId: receiverId,
//         textMessage: fileUrl,
//         type: messageType,
//         timeSent: timeSent,
//         messageId: messageId,
//         status: MessageStatus.pending,
//       );

//       await saveToMessageCollection(message);
//       await saveAsLastMessage(senderData, receiverId, lastMessage, timeSent);
//     } catch (e) {
//       showAlertDialog(context: context, message: e.toString());
//     }
//   }

//   String _getLastMessageByType(MessageType messageType) {
//     switch (messageType) {
//       case MessageType.image:
//         return '📸 Photo message';
//       case MessageType.audio:
//         return '🎤 Voice message';
//       case MessageType.video:
//         return '🎥 Video message';
//       case MessageType.gif:
//         return 'GIF message';
//       default:
//         return 'Message';
//     }
//   }

//   Future<void> sendTextMessage({
//     required BuildContext context,
//     required String textMessage,
//     required String receiverId,
//     required UserModel senderData,
//   }) async {
//     try {
//       final isOnline = await isConnected();
//       if (!isOnline) {
//         // Si pas de connexion, sauvegarder localement
//         saveMessageLocally(
//             textMessage, receiverId, senderData, MessageType.text);
//         showAlertDialog(
//             context: context,
//             message:
//                 'Pas de connexion. Le message sera envoyé une fois la connexion rétablie.');
//         // monitorConnectivityChanges(receiverId);
//         return;
//       }

//       final timeSent = DateTime.now();
//       final messageId = const Uuid().v1();

//       // Vérifiez si le destinataire est en ligne
//       final receiverDoc =
//           await firestore.collection('users').doc(receiverId).get();
//       final bool isReceiverOnline =
//           receiverDoc.exists && (receiverDoc.data()?['active'] ?? false);

//       final status =
//           isReceiverOnline ? MessageStatus.delivered : MessageStatus.pending;

//       final message = MessageModel(
//         senderId: senderData.uid,
//         receiverId: receiverId,
//         textMessage: textMessage,
//         type: MessageType.text,
//         timeSent: timeSent,
//         messageId: messageId,
//         status: status,
//       );

//       await saveToMessageCollection(message);
//       await saveAsLastMessage(senderData, receiverId, textMessage, timeSent);

//       // Si le message est en attente, surveiller le statut du destinataire
//       if (status == MessageStatus.pending) {
//         monitorReceiverStatus(receiverId);
//       }
//     } catch (e) {
//       showAlertDialog(context: context, message: e.toString());
//     }
//   }

//   Future<void> saveMessageLocally(var messageContent, String receiverId,
//       UserModel senderData, MessageType messageType) async {
//     var box = await Hive.openBox('offline_messages');
//     var message = {
//       'messageContent': messageContent,
//       'receiverId': receiverId,
//       'senderId': senderData.uid,
//       'messageType': messageType.toString(),
//       'timeSent': DateTime.now().toIso8601String(),
//       'status': MessageStatus.pending.toString(),
//     };

//     await box.add(message);
//     print("Message sauvegardé localement : $messageContent pour $receiverId");
//   }

//   Future<List<MessageModel>> retrievePendingMessages() async {
//     var box = await Hive.openBox('offline_messages');
//     List<MessageModel> pendingMessages = [];

//     for (var message in box.values) {
//       pendingMessages.add(MessageModel(
//         senderId: message['senderId'],
//         receiverId: message['receiverId'],
//         textMessage: message['messageContent'],
//         type: message['messageType'].toEnum(),
//         timeSent: DateTime.parse(message['timeSent']),
//         messageId: const Uuid().v1(),
//         status: MessageStatus.pending,
//       ));
//     }

//     return pendingMessages;
//   }

//   Future<void> saveToMessageCollection(MessageModel message) async {
//     await firestore
//         .collection('users')
//         .doc(auth.currentUser!.uid)
//         .collection('chats')
//         .doc(message.receiverId)
//         .collection('messages')
//         .doc(message.messageId)
//         .set(message.toMap());
//     await firestore
//         .collection('users')
//         .doc(message.receiverId)
//         .collection('chats')
//         .doc(auth.currentUser!.uid)
//         .collection('messages')
//         .doc(message.messageId)
//         .set(message.toMap());
//   }

//   Future<void> saveAsLastMessage(UserModel senderUserData, String receiverId,
//       String lastMessage, DateTime timeSent) async {
//     // Modèle pour l'expéditeur (l'utilisateur actuel)
//     final senderLastMessageModel = LastMessageModel(
//       username: senderUserData.username,
//       profileImageUrl: senderUserData.profileImageUrl,
//       contactId: receiverId, // UID du destinataire dans le chat de l'expéditeur
//       timeSent: timeSent,
//       lastMessage: lastMessage,
//       email: senderUserData.email,
//     );

//     // Enregistrer pour l'expéditeur (mise à jour du dernier message envoyé)
//     await firestore
//         .collection('users')
//         .doc(senderUserData.uid)
//         .collection('chats')
//         .doc(receiverId) // Utiliser l'UID du destinataire
//         .set(senderLastMessageModel.toMap(), SetOptions(merge: true));

//     // Récupérer les informations du destinataire pour son propre affichage du chat
//     final receiverDoc =
//         await firestore.collection('users').doc(receiverId).get();
//     if (!receiverDoc.exists) {
//       print("Erreur : utilisateur destinataire non trouvé.");
//       return;
//     }

//     final receiverData = UserModel.fromMap(receiverDoc.data()!);

//     // Modèle pour le destinataire (le contact de l'expéditeur)
//     final receiverLastMessageModel = LastMessageModel(
//       username: receiverData.username,
//       profileImageUrl: receiverData.profileImageUrl,
//       contactId: senderUserData
//           .uid, // UID de l'expéditeur dans le chat du destinataire
//       timeSent: timeSent,
//       lastMessage: lastMessage,
//       email: receiverData.email,
//     );

//     // Enregistrer pour le destinataire (mise à jour du dernier message reçu)
//     await firestore
//         .collection('users')
//         .doc(receiverId) // Le destinataire
//         .collection('chats')
//         .doc(senderUserData.uid) // Utiliser l'UID de l'expéditeur
//         .set(receiverLastMessageModel.toMap(), SetOptions(merge: true));
//   }

//   Future<void> updateMessageStatus({
//     required String messageId,
//     required MessageStatus status,
//     required String receiverId,
//   }) async {
//     final senderDocRef = firestore
//         .collection('users')
//         .doc(auth.currentUser!.uid)
//         .collection('chats')
//         .doc(receiverId)
//         .collection('messages')
//         .doc(messageId);

//     final receiverDocRef = firestore
//         .collection('users')
//         .doc(receiverId)
//         .collection('chats')
//         .doc(auth.currentUser!.uid)
//         .collection('messages')
//         .doc(messageId);

//     try {
//       // Vérification d'existence pour le document de l'expéditeur
//       final senderDocSnapshot = await senderDocRef.get();
//       if (senderDocSnapshot.exists) {
//         await senderDocRef.update({'status': status.toString()});
//       } else {
//         print('Document du message pour l\'expéditeur non trouvé : $messageId');
//       }

//       // Vérification d'existence pour le document du destinataire
//       final receiverDocSnapshot = await receiverDocRef.get();
//       if (receiverDocSnapshot.exists) {
//         await receiverDocRef.update({'status': status.toString()});
//       } else {
//         print(
//             'Document du message pour le destinataire non trouvé : $messageId');
//       }
//     } catch (e) {
//       print('Erreur lors de la mise à jour du statut du message : $e');
//     }
//   }

//   Stream<List<MessageModel>> getAllOneToOneMessages(String receiverId) {
//     return firestore
//         .collection('users')
//         .doc(auth.currentUser!.uid)
//         .collection('chats')
//         .doc(receiverId)
//         .collection('messages')
//         .orderBy('timeSent')
//         .snapshots()
//         .map((event) {
//       return event.docs
//           .map((message) => MessageModel.fromMap(message.data()))
//           .toList();
//     });
//   }

//   Stream<List<LastMessageModel>> getAllLastMessageList() {
//     return firestore
//         .collection('users')
//         .doc(auth.currentUser!.uid)
//         .collection('chats')
//         .orderBy('timeSent')
//         .snapshots()
//         .asyncMap((event) async {
//       final uniqueContacts = <String, LastMessageModel>{};

//       if (event.docs.isEmpty) {
//         return []; // Retournez une liste vide si aucun document n'est trouvé
//       }

//       for (var document in event.docs) {
//         final lastMessage = LastMessageModel.fromMap(document.data());
//         if (!uniqueContacts.containsKey(lastMessage.contactId)) {
//           try {
//             final userData = await firestore
//                 .collection('users')
//                 .doc(lastMessage.contactId)
//                 .get();
//             if (userData.exists) {
//               final user = UserModel.fromMap(userData.data()!);
//               uniqueContacts[lastMessage.contactId] = LastMessageModel(
//                 username: user.username,
//                 profileImageUrl: user.profileImageUrl,
//                 contactId: lastMessage.contactId,
//                 timeSent: lastMessage.timeSent,
//                 lastMessage: lastMessage.lastMessage,
//                 email: lastMessage.email,
//               );
//             }
//           } catch (e) {
//             print('Erreur lors de la récupération des données utilisateur: $e');
//           }
//         }
//       }
//       return uniqueContacts.values.toList();
//     });
//   }
// }





  // void sendTextMessage({
  //   required BuildContext context,
  //   required String textMessage,
  //   required String receiverId,
  //   required UserModel senderData,
  //   required MessageReply? messageReply,
  //   required bool isGroupChat,
  // }) async {
  //   try {
  //     final timeSent = DateTime.now();
  //     UserModel? receiverData;

  //     // Récupérer les données du destinataire si ce n'est pas un chat de groupe
  //     if (!isGroupChat) {
  //       if (receiverId.isEmpty) {
  //         print("Le receiverId est vide.");
  //         return;
  //       }
  //       print("Le receiverId n'est pas vide.");
  //       final receiverDataMap =
  //           await firestore.collection('users').doc(receiverId).get();
  //       // Vérifie que les données existent avant de créer l'utilisateur
  //       if (receiverDataMap.exists) {
  //         receiverData = UserModel.fromMap(receiverDataMap.data()!);
  //       } else {
  //         // Gestion d'erreur si l'utilisateur n'existe pas
  //         print("L'utilisateur avec l'ID $receiverId n'existe pas.");
  //         return;
  //       }
  //     }

  //     // Génération de l'ID du message unique
  //     final textMessageId = const Uuid().v1();

  //     print('Sender ID: ${senderData.uid}');
  //     print('Receiver ID: $receiverId');
  //     print('Text Message: $textMessage');
  //     print('Replied Message: ${messageReply?.message}');
  //     print(
  //         'Replied To: ${messageReply == null ? '' : messageReply.isMe ? (senderData.username ?? 'Utilisateur inconnu') : (receiverData?.username ?? 'Utilisateur inconnu')}');
  //     print('Receiver Username: ${receiverData?.username}');

  //     // Création du modèle de message local
  //     final localMessage = MessageModel(
  //       senderId: senderData.uid,
  //       receiverId: receiverId,
  //       textMessage: textMessage,
  //       type: myMessageType.MessageType.text,
  //       timeSent: timeSent,
  //       messageId: textMessageId,
  //       status: MessageStatus.pending,
  //       repliedMessage: messageReply?.message ?? '',
  //       repliedTo: messageReply == null
  //           ? ''
  //           : messageReply.isMe
  //               ? senderData.username
  //               : receiverData?.username ?? '',
  //       repliedMessageType:
  //           messageReply?.messageType ?? myMessageType.MessageType.text,
  //     );

  //     // Vérifier si le message n'a pas déjà été sauvegardé localement
  //     if (!await messageExistsLocally(textMessageId)) {
  //       await saveMessageLocally(localMessage);
  //       final localMessages = await getLocalMessages(receiverId);
  //       _messageController.add(localMessages);
  //     } else {
  //       print("Le message ${textMessageId} existe déjà localement.");
  //       return; // Arrêter l'exécution si le message existe déjà
  //     }

  //     // Vérifier la connectivité réseau
  //     bool isConnected = await isConnectedToNetwork();

  //     if (isConnected) {
  //       await saveToMessageCollection(
  //         receiverId: receiverId,
  //         textMessage: textMessage,
  //         timeSent: timeSent,
  //         textMessageId: textMessageId,
  //         senderUsername: senderData.username,
  //         receiverUsername: receiverData?.username ?? 'Utilisateur inconnu',
  //         messageType: myMessageType.MessageType.text,
  //         messageReply: messageReply,
  //         isGroupChat: isGroupChat,
  //       );
  //       saveAsLastMessage(
  //         senderUserData: senderData,
  //         receiverUserData: receiverData,
  //         lastMessage: textMessage,
  //         timeSent: timeSent,
  //         receiverId: receiverId,
  //         isGroupChat: isGroupChat,
  //       );

  //       // Mise à jour du statut une fois envoyé
  //       await updateMessageStatus(
  //         messageId: textMessageId,
  //         status: MessageStatus.sent,
  //         receiverId: receiverId,
  //       );

  //       // Mettre à jour sqlite une fois le message envoyé
  //       await updateMessageStatusInSQLite(textMessageId, MessageStatus.sent);
  //       List<MessageModel> pendingMessages =
  //           await getPendingMessagesFromSQLite();
  //       for (MessageModel pendingMessage in pendingMessages) {
  //         await saveToMessageCollection(
  //           receiverId: pendingMessage.receiverId,
  //           textMessage: pendingMessage.textMessage,
  //           timeSent: pendingMessage.timeSent,
  //           textMessageId: pendingMessage.messageId,
  //           senderUsername: pendingMessage.senderId,
  //           receiverUsername: receiverData?.username ?? 'Utilisateur inconnu',
  //           messageType: pendingMessage.type,
  //           messageReply: null, // Ajuste si nécessaire
  //           isGroupChat: isGroupChat, // Ajuste si nécessaire
  //         );
  //       }
  //       await syncMessages(receiverId);
  //     } else {
  //       print(
  //           "Message sauvegardé localement. Il sera envoyé lorsque la connexion sera rétablie.");
  //     }
  //   } catch (e) {
  //     if (context.mounted) {
  //       print('pour sendtext message on a:  ${e.toString()}');
  //       showAlertDialog(
  //           context: context,
  //           message: 'pour sendtext message on a:  ${e.toString()}');
  //     }
  //   }
  // }



  //est ce que pour affiche les messages on ne peut pas faire de maniere que si online or offline il retourne toujour les messages car je vois que si j'ecrit un message online directe est affiche dans les messages bien mais si j'envoie oflline il ne s'affiche pas directement: Stream<List<MessageModel>> getAllOneToOneMessage(String receiverId) async* { 
  //   try {
  //     // Charger les messages locaux en premier
  //     final localMessages = await getLocalMessages(receiverId);
  //     if (localMessages.isNotEmpty) {
  //       yield localMessages;
  //     }

  //     final isConnected = await isConnectedToNetwork();

  //     if (isConnected) {
  //       print('Récupération des messages depuis Firestore :');
  //       // Charger les messages depuis Firestore
  //       yield* firestore
  //           .collection('users')
  //           .doc(auth.currentUser!.uid)
  //           .collection('chats')
  //           .doc(receiverId)
  //           .collection('messages')
  //           .orderBy('timeSent', descending: false)
  //           .snapshots()
  //           .map((snapshot) {
  //         if (snapshot.docs.isEmpty) {
  //           print('Aucun message trouvé pour ce destinataire.');
  //           return <MessageModel>[]; // Retourner une liste vide si aucun message
  //         }

  //         final messages = snapshot.docs.map((doc) {
  //           var data = doc.data();

  //           print('Message ID: ${doc.id}, Status: ${data['status']}');

  //           return MessageModel.fromMap({
  //             'messageId': doc.id,
  //             'senderId': data['senderId'],
  //             'receiverId': data['receiverId'],
  //             'textMessage': data['textMessage'],
  //             'type': data['type'],
  //             'timeSent': data['timeSent'],
  //             'status': data['status'],
  //             'repliedMessage': data['repliedMessage'] ?? '',
  //             'repliedTo': data['repliedTo'] ?? '',
  //             'repliedMessageType': data['repliedMessageType'] ?? '',
  //           });
  //         }).toList();

  //         // Synchroniser avec SQLite
  //         _syncMessagesWithSQLite(messages);

  //         return messages;
  //       }).handleError((error) {
  //         print(
  //             'Erreur lors de la récupération des messages depuis Firestore: $error');
  //         return <MessageModel>[]; // En cas d'erreur, renvoyer une liste vide
  //       });
  //     } else {
  //       print('Récupération des messages depuis SQLITE :');
  //       yield localMessages;
  //     }
  //   } catch (error) {
  //     print('Erreur dans getAllOneToOneMessage: $error');
  //     yield <MessageModel>[]; // En cas d'erreur, renvoyer une liste vide
  //   }
  // } Future<void> sendTextMessage({
  //   required BuildContext context,
  //   required String textMessage,
  //   required String receiverId,
  //   required UserModel senderData,
  //   required MessageReply? messageReply,
  //   required bool isGroupChat,
  // }) async {
  //   try {
  //     final timeSent = DateTime.now();
  //     UserModel? receiverData;

  //     // Récupérer les données du destinataire si ce n'est pas un chat de groupe
  //     if (!isGroupChat) {
  //       receiverData = await _getReceiverData(receiverId);
  //       if (receiverData == null)
  //         return; // Sortir si l'utilisateur n'existe pas
  //     }

  //     // Génération de l'ID du message unique
  //     final textMessageId = const Uuid().v1();

  //     // Création du modèle de message local
  //     final localMessage = _createLocalMessage(
  //       textMessageId,
  //       senderData,
  //       receiverId,
  //       textMessage,
  //       timeSent,
  //       messageReply,
  //       receiverData, // Passer receiverData ici
  //     );

  //     // Sauvegarder localement
  //     await _saveLocalMessageIfNotExists(localMessage, receiverId);

  //     // Vérifier la connectivité réseau
  //     bool isConnected = await isConnectedToNetwork();
  //     if (isConnected) {
  //       await _sendMessageToFirestore(
  //           receiverId,
  //           senderData,
  //           textMessage,
  //           timeSent,
  //           textMessageId,
  //           messageReply,
  //           isGroupChat,
  //           receiverData); // Passer receiverData ici
  //       await _syncPendingMessages(
  //           receiverId, receiverData, isGroupChat); // Passer receiverData ici
  //     } else {
  //       print(
  //           "Message sauvegardé localement. Il sera envoyé lorsque la connexion sera rétablie.");
  //     }
  //   } catch (e) {
  //     if (context.mounted) {
  //       print('Erreur lors de l\'envoi du message: ${e.toString()}');
  //       showAlertDialog(
  //           context: context,
  //           message: 'Erreur lors de l\'envoi du message: ${e.toString()}');
  //     }
  //   }
  // }

  // Future<UserModel?> _getReceiverData(String receiverId) async {
  //   if (receiverId.isEmpty) {
  //     print("Le receiverId est vide.");
  //     return null;
  //   }

  //   final receiverDataMap =
  //       await firestore.collection('users').doc(receiverId).get();
  //   if (receiverDataMap.exists) {
  //     return UserModel.fromMap(receiverDataMap.data()!);
  //   } else {
  //     print("L'utilisateur avec l'ID $receiverId n'existe pas.");
  //     return null;
  //   }
  // }

  // MessageModel _createLocalMessage(
  //   String messageId,
  //   UserModel senderData,
  //   String receiverId,
  //   String textMessage,
  //   DateTime timeSent,
  //   MessageReply? messageReply,
  //   UserModel? receiverData, // Recevoir receiverData ici
  // ) {
  //   return MessageModel(
  //     senderId: senderData.uid,
  //     receiverId: receiverId,
  //     textMessage: textMessage,
  //     type: myMessageType.MessageType.text,
  //     timeSent: timeSent,
  //     messageId: messageId,
  //     status: MessageStatus.pending,
  //     repliedMessage: messageReply?.message ?? '',
  //     repliedTo: messageReply == null
  //         ? ''
  //         : messageReply.isMe
  //             ? senderData.username
  //             : receiverData?.username ?? '',
  //     repliedMessageType:
  //         messageReply?.messageType ?? myMessageType.MessageType.text,
  //   );
  // }

  // Future<void> _saveLocalMessageIfNotExists(
  //     MessageModel localMessage, String receiverId) async {
  //   if (!await messageExistsLocally(localMessage.messageId)) {
  //     await saveMessageLocally(localMessage);
  //     final localMessages = await getLocalMessages(receiverId);
  //     _messageController.add(localMessages);
  //   } else {
  //     print("Le message ${localMessage.messageId} existe déjà localement.");
  //   }
  // }

  // Future<void> _sendMessageToFirestore(
  //   String receiverId,
  //   UserModel senderData,
  //   String textMessage,
  //   DateTime timeSent,
  //   String messageId,
  //   MessageReply? messageReply,
  //   bool isGroupChat,
  //   UserModel? receiverData, // Passer receiverData ici
  // ) async {
  //   await saveToMessageCollection(
  //     receiverId: receiverId,
  //     textMessage: textMessage,
  //     timeSent: timeSent,
  //     textMessageId: messageId,
  //     senderUsername: senderData.username,
  //     receiverUsername: receiverData?.username ??
  //         'Utilisateur inconnu', // Utiliser receiverData ici
  //     messageType: myMessageType.MessageType.text,
  //     messageReply: messageReply,
  //     isGroupChat: isGroupChat,
  //   );
  //   await saveAsLastMessage(
  //     senderUserData: senderData,
  //     receiverUserData: receiverData,
  //     lastMessage: textMessage,
  //     timeSent: timeSent,
  //     receiverId: receiverId,
  //     isGroupChat: isGroupChat,
  //   );

  //   // Mise à jour du statut une fois envoyé
  //   await updateMessageStatus(
  //       messageId: messageId,
  //       status: MessageStatus.sent,
  //       receiverId: receiverId);
  //   await updateMessageStatusInSQLite(messageId, MessageStatus.sent);
  // }

  // Future<void> _syncPendingMessages(
  //     String receiverId, UserModel? receiverData, bool isGroupChat) async {
  //   List<MessageModel> pendingMessages = await getPendingMessagesFromSQLite();
  //   for (MessageModel pendingMessage in pendingMessages) {
  //     await saveToMessageCollection(
  //       receiverId: pendingMessage.receiverId,
  //       textMessage: pendingMessage.textMessage,
  //       timeSent: pendingMessage.timeSent,
  //       textMessageId: pendingMessage.messageId,
  //       senderUsername: pendingMessage.senderId,
  //       receiverUsername: receiverData?.username ??
  //           'Utilisateur inconnu', // Utiliser receiverData ici
  //       messageType: pendingMessage.type,
  //       messageReply: null,
  //       isGroupChat: isGroupChat,
  //     );
  //   }
  // }  par exemple pour whatsapp si on envoie un message meme offline on te montre le message directement avec status pending si tu ouvre la connection on ne load pas meme la page mais on reenvoye le message pending alors je voulais faire de la meme maniere svp aide moi