import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/models/status_model.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/repository/firebase_storage_repository.dart';
import 'package:tuyage/feature/contact/repository/contact_repository.dart';
import 'package:uuid/uuid.dart';

final statusRepositoryProvider = Provider((ref) => StatusRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
      ref: ref,
    ));

class StatusRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final ProviderRef ref;

  StatusRepository({
    required this.firestore,
    required this.auth,
    required this.ref,
  });

  Future<void> uploadStatus({
    required String username,
    required String profilePic,
    required String phoneNumber,
    required File statusImage,
    required BuildContext context,
  }) async {
    try {
      var statusId = const Uuid().v1();
      String uid = auth.currentUser!.uid;

      // Store status image in Firebase Storage
      String imageUrl = await ref
          .read(firebaseStorageRepositoryProvider)
          .storeFileToFirebase('/status/$statusId$uid', statusImage);
      print("Image URL uploaded: $imageUrl");

      // Get firebaseContacts using getAllContacts
      var contactsRepository = ref.read(contactsRepositoryProvider);
      var contactsList = await contactsRepository.getAllContacts();
      List<UserModel> firebaseContacts =
          contactsList[0]; // Récupérer uniquement firebaseContacts

      // Ajouter tous les UID des firebaseContacts à uidWhoCanSee
      List<String> uidWhoCanSee =
          firebaseContacts.map((contact) => contact.uid).toList();

      // Save status to Firestore
      List<String> statusImageUrls = [];
      var statusSnapshot = await firestore
          .collection('status')
          .where('uid', isEqualTo: uid)
          .get();

      if (statusSnapshot.docs.isNotEmpty) {
        Status status = Status.fromMap(statusSnapshot.docs[0].data());
        statusImageUrls = status.photoUrl;
        statusImageUrls.add(imageUrl);
        await firestore
            .collection('status')
            .doc(statusSnapshot.docs[0].id)
            .update({'photoUrl': statusImageUrls});
        print("Status updated with new image URL.");
      } else {
        // Create a new status
        statusImageUrls = [imageUrl];
        Status status = Status(
          uid: uid,
          username: username,
          phoneNumber: phoneNumber,
          profilePic: profilePic,
          statusId: statusId,
          createdAt: DateTime.now(),
          photoUrl: statusImageUrls,
          whoCanSee: uidWhoCanSee,
        );

        await firestore
            .collection('status')
            .doc(statusId)
            .set(status.toMap())
            .then((_) {
          ;
        }).catchError((error) {
          print("Error saving status to Firestore: $error");
          showAlertDialog(context: context, message: error.toString());
        });
      }
    } catch (e) {
      print("Error uploading status: $e");
      showAlertDialog(context: context, message: e.toString());
    }
  }

  Future<List<Status>> getStatus(BuildContext context) async {
    List<Status> statusData = [];
    try {
      var contactsRepository = ref.read(contactsRepositoryProvider);
      var contactsList = await contactsRepository.getAllContacts();
      List<UserModel> contacts = contactsList[0];

      for (int i = 0; i < contacts.length; i++) {
        var statusesSnapchot = await firestore
            .collection('status')
            .where(
              'phoneNumber',
              isEqualTo: contacts[i].phoneNumber.replaceAll(
                    ' ',
                    '',
                  ),
            )
            .where(
              'createdAt',
              isGreaterThan: DateTime.now()
                  .subtract(const Duration(hours: 24))
                  .millisecondsSinceEpoch,
            )
            .get();
        for (var tempData in statusesSnapchot.docs) {
          Status tempStatus = Status.fromMap(tempData.data());
          if (tempStatus.whoCanSee.contains(auth.currentUser!.uid)) {
            statusData.add(tempStatus);
          }
        }
      }
    } catch (e) {
      showAlertDialog(context: context, message: e.toString());
      return [];
    }
    return statusData;
  }
}
