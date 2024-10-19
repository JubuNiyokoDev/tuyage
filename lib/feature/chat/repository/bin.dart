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
