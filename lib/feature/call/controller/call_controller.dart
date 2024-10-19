import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/models/call.dart';
import 'package:tuyage/feature/auth/controller/auth_controller.dart';
import 'package:tuyage/feature/call/respository/call_repository.dart';
import 'package:uuid/uuid.dart';

final callControllerProvider = Provider((ref) {
  final callRepository = ref.read(callRepositoryProvider);
  return CallController(
    callRepository: callRepository,
    ref: ref,
    auth: FirebaseAuth.instance,
  );
});

class CallController {
  final CallRepository callRepository;
  final ProviderRef ref;
  final FirebaseAuth auth;

  CallController({
    required this.callRepository,
    required this.ref,
    required this.auth,
  });

  Stream<DocumentSnapshot> get callStream => callRepository.callStream;

  void makeCall(
    BuildContext context,
    String receiverName,
    String receiverId,
    String receiverProfilePic,
    bool isGroupChat,
  ) {
    ref.read(userInfoAuthProvider).whenData((value) {
      String callId = const Uuid().v1();
      Call senderCallData = Call(
        callerId: auth.currentUser!.uid,
        callerName: value!.username,
        callerPic: value.profileImageUrl,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverPic: receiverProfilePic,
        callId: callId,
        hasDialled: true,
      );

      Call receiverCallData = Call(
        callerId: auth.currentUser!.uid,
        callerName: value.username,
        callerPic: value.profileImageUrl,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverPic: receiverProfilePic,
        callId: callId,
        hasDialled: false,
      );

      if (isGroupChat) {
        callRepository.makeGroupCall(senderCallData, receiverCallData, context);
      } else {
        callRepository.makeCall(senderCallData, receiverCallData, context);
      }
    });
  }

  void endCall(
    String callerId,
    String receiverId,
    BuildContext context,
  ) {
    callRepository.endCall(callerId, receiverId, context);
  }
}
