import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/repository/firebase_storage_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:tuyage/common/models/group.dart' as model;

final groupRepositoryProvider = Provider((ref) => GroupRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
      ref: ref,
    ));

class GroupRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final ProviderRef ref;

  GroupRepository({
    required this.firestore,
    required this.auth,
    required this.ref,
  });

  void createGroup(BuildContext context, String name, File? groupPic,
      List<UserModel> selectedContact) async {
    try {
      List<String> uids = [];

      for (int i = 0; i < selectedContact.length; i++) {
        var userCollection = await firestore
            .collection('users')
            .where('phoneNumber',
                isEqualTo: selectedContact[i].phoneNumber.replaceAll(' ', ''))
            .get();

        if (userCollection.docs.isNotEmpty && userCollection.docs[0].exists) {
          String uid = userCollection.docs[0].data()['uid'];
          if (!uids.contains(uid)) {
            uids.add(uid);
          }
        }
      }

      if (!uids.contains(auth.currentUser!.uid)) {
        uids.add(auth.currentUser!.uid);
      }

      var groupId = const Uuid().v1();
      String groupPicUrl =
          await ref.read(firebaseStorageRepositoryProvider).storeFileToFirebase(
                'group/$groupId',
                groupPic,
              );

      model.Group group = model.Group(
        senderId: auth.currentUser!.uid,
        name: name,
        groupId: groupId,
        lastMessage: '',
        groupPic: groupPicUrl,
        membersUid: uids, // Liste sans duplications
        timeSent: DateTime.now(),
      );
      await firestore.collection('groups').doc(groupId).set(group.toMap());
    } catch (e) {
      showAlertDialog(context: context, message: e.toString());
    }
  }

  Future<model.Group?> getGroupById(String groupId) async {
    try {
      DocumentSnapshot doc =
          await firestore.collection('groups').doc(groupId).get();

      if (doc.exists) {
        return model.Group.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        print("Groupe non trouvé avec l'ID: $groupId");
        return null;
      }
    } catch (e) {
      print("Erreur lors de la récupération du groupe: $e");
      return null;
    }
  }
}
