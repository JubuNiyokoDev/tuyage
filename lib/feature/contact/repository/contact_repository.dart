import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/models/user_model.dart';

final contactsRepositoryProvider = Provider(
  (ref) {
    return ContactsRepository(firestore: FirebaseFirestore.instance);
  },
);

class ContactsRepository {
  final FirebaseFirestore firestore;

  ContactsRepository({required this.firestore});

  Future<List<List<UserModel>>> getAllContacts() async {
    List<UserModel> firebaseContacts = [];
    List<UserModel> phoneContacts = [];

    try {
      if (await FlutterContacts.requestPermission()) {
        final userCollection = await firestore.collection('users').get();
        final allContactsInThePhone = await FlutterContacts.getContacts(
          withProperties: true,
        );

        for (var contact in allContactsInThePhone) {
          if (contact.phones.isNotEmpty) {
            String phoneNumber = contact.phones[0].number.replaceAll(' ', '');

            bool isContactFound = false;

            for (var firebaseContactData in userCollection.docs) {
              var firebaseContact =
                  UserModel.fromMap(firebaseContactData.data());
              String firebasePhoneNumber =
                  firebaseContact.phoneNumber.replaceAll(' ', '');

              if (phoneNumber == firebasePhoneNumber) {
                firebaseContacts.add(firebaseContact);
                isContactFound = true;
                break;
              }
            }

            if (!isContactFound) {
              phoneContacts.add(
                UserModel(
                  username: contact.displayName,
                  uid: '',
                  profileImageUrl: '',
                  active: false,
                  lastSeen: 0,
                  phoneNumber: phoneNumber,
                  groupId: [],
                  email: '',
                ),
              );
            }
          } else {
            print('Contact ${contact.displayName} has no phone number.');
          }
        }
      }
    } catch (e) {
      print(e.toString());
    }
    return [firebaseContacts, phoneContacts];
  }
}
