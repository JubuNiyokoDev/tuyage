import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/models/call.dart';
import 'package:tuyage/common/models/group.dart' as model;
import 'package:tuyage/feature/call/screens/call_screen.dart';

final callRepositoryProvider = Provider((ref) => CallRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    ));

class CallRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CallRepository({
    required this.firestore,
    required this.auth,
  });

  Stream<DocumentSnapshot> get callStream =>
      firestore.collection('calls').doc(auth.currentUser!.uid).snapshots();

  void makeCall(
    Call senderCallData,
    Call receiverCallData,
    BuildContext context,
  ) async {
    try {
      await firestore
          .collection('calls')
          .doc(senderCallData.callerId)
          .set(senderCallData.toMap());
      await firestore
          .collection('calls')
          .doc(receiverCallData.receiverId)
          .set(receiverCallData.toMap());

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            call: senderCallData,
            channelId: senderCallData.callId,
            isGroupChat: false,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        showAlertDialog(context: context, message: e.toString());
      }
    }
  }

  void makeGroupCall(
    Call senderCallData,
    Call receiverCallData,
    BuildContext context,
  ) async {
    try {
      await firestore
          .collection('calls')
          .doc(senderCallData.callerId)
          .set(senderCallData.toMap());
      var gorupSnapshot = await firestore
          .collection('groups')
          .doc(senderCallData.receiverId)
          .get();
      model.Group group = model.Group.fromMap(gorupSnapshot.data()!);

      for (var id in group.membersUid) {
        await firestore
            .collection('calls')
            .doc(id)
            .set(receiverCallData.toMap());
      }
      await firestore
          .collection('calls')
          .doc(receiverCallData.receiverId)
          .set(receiverCallData.toMap());

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            call: senderCallData,
            channelId: senderCallData.callId,
            isGroupChat: true,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        showAlertDialog(context: context, message: e.toString());
      }
    }
  }

  void endCall(
    String callerId,
    String receiverId,
    BuildContext context,
  ) async {
    try {
      await firestore.collection('calls').doc(callerId).delete();
      await firestore.collection('calls').doc(receiverId).delete();

      Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        showAlertDialog(context: context, message: e.toString());
      }
    }
  }

  void endGroupCall(
    String callerId,
    String receiverId,
    BuildContext context,
  ) async {
    try {
      await firestore.collection('calls').doc(callerId).delete();
      var gorupSnapshot =
          await firestore.collection('groups').doc(receiverId).get();
      model.Group group = model.Group.fromMap(gorupSnapshot.data()!);
      for (var id in group.membersUid) {
        await firestore.collection('calls').doc(id).delete();
      }
      Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        showAlertDialog(context: context, message: e.toString());
      }
    }
  }
}
