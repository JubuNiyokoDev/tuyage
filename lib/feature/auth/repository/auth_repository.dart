import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/helper/show_loading_dialog.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/repository/firebase_storage_repository.dart';
import 'package:tuyage/common/routes/routes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    realtime: FirebaseDatabase.instance,
    firebaseStorage: FirebaseStorage.instance,
  );
});

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseDatabase realtime;
  final FirebaseStorage firebaseStorage;
  late WebSocketChannel channel;

  AuthRepository({
    required this.auth,
    required this.firestore,
    required this.realtime,
    required this.firebaseStorage,
  }) {
    // Établir la connexion WebSocket lors de l'initialisation
    channel = WebSocketChannel.connect(
      Uri.parse('wss://tuyage-server.onrender.com'),
    );
  }

  Future<void> updateUserPresenceToOffline(
      BuildContext context, String uid) async {
    if (auth.currentUser == null) {
      print("Aucun utilisateur connecté pour mettre à jour la présence.");
      return; // Sortir si l'utilisateur n'est pas authentifié
    }

    final offline = {
      'active': false,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await realtime.ref().child(uid).update(offline);
      await firestore.collection('users').doc(uid).update(offline);
      print('User presence updated to offline for UID: $uid');
    } catch (e) {
      print('Failed to update user presence to offline: $e');
      showAlertDialog(
          context: context,
          message: "Erreur lors de la mise à jour du statut.");
    }
  }

  Stream<UserModel?> getUserById(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!);
      } else {
        return null;
      }
    });
  }

  Stream<ConnectivityResult> getUserPresenceStatus({required String uid}) {
    return realtime.ref().child(uid).onValue.map((event) {
      final value = event.snapshot.value;

      if (value is Map) {
        final isActive = value['active'] as bool? ?? false;
        return isActive ? ConnectivityResult.mobile : ConnectivityResult.none;
      } else {
        print('Unexpected value type: ${value.runtimeType}');
        return ConnectivityResult.none;
      }
    });
  }

  void signupWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String phoneNumber,
    required String password,
    required String username,
    required WidgetRef ref,
    required String countryCode,
  }) async {
    try {
      showLoadingDialog(context: context, message: "Inscription en cours...");
      final credential = await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await credential.user?.sendEmailVerification();

      String numero =
          normalizePhoneNumber(phoneNumber, countryCode: countryCode);

      await saveUserInfoToFirestore(
        username: username,
        phoneNumber: numero,
        profileImage: '',
        context: context,
        mounted: true,
        email: email,
        ref: ref,
      );

      Navigator.pushNamedAndRemoveUntil(
          context, Routes.login, (route) => false);
      showAlertDialog(
          context: context,
          message: "Veuillez vérifier votre email avant de vous connecter.");
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showAlertDialog(
          context: context, message: e.message ?? "Une erreur s'est produite.");
    } catch (e) {
      Navigator.pop(context);
      showAlertDialog(
          context: context,
          message: "Une erreur s'est produite : ${e.toString()}");
    }
  }

  void loginWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      showLoadingDialog(context: context, message: "Connexion en cours...");
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
        UserModel? user = await getCurrentUserInfo();
        if (user != null) {
          updateUserPresence();
          Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.userInfo, (route) => false,
              arguments: user);
        }
      } else {
        Navigator.pop(context);
        showAlertDialog(
            context: context,
            message: "Veuillez vérifier votre email avant de vous connecter.");
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showAlertDialog(
          context: context, message: e.message ?? "Une erreur s'est produite.");
    } catch (e) {
      Navigator.pop(context);
      showAlertDialog(
          context: context,
          message: "Une erreur s'est produite : ${e.toString()}");
    }
  }

  String normalizePhoneNumber(String phoneNumber, {String? countryCode}) {
    String normalized = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (countryCode != null && !normalized.startsWith('+')) {
      normalized = '+$countryCode$normalized';
    }

    return normalized;
  }

  Future<String> saveUserInfoToFirestore({
    required String username,
    required dynamic profileImage,
    required BuildContext context,
    required bool mounted,
    required String email,
    required WidgetRef ref,
    required String phoneNumber,
  }) async {
    if (auth.currentUser == null) {
      showAlertDialog(
          context: context,
          message:
              "Vous devez être connecté pour sauvegarder vos informations.");
      return '';
    }

    String uid = auth.currentUser!.uid;
    String profileImageUrl = '';

    // Téléchargement de l'image si nécessaire
    if (profileImage != null && profileImage is! String) {
      profileImageUrl = await ref
          .read(firebaseStorageRepositoryProvider)
          .storeFileToFirebase('profileImage/$uid', profileImage);
    } else if (profileImage is String) {
      profileImageUrl = profileImage;
    }

    // Créer l'objet utilisateur et sauvegarder
    UserModel user = UserModel(
      email: email,
      username: username,
      uid: uid,
      profileImageUrl: profileImageUrl,
      active: true,
      lastSeen: DateTime.now().millisecondsSinceEpoch,
      phoneNumber: phoneNumber,
      groupId: [],
    );

    try {
      await firestore.collection('users').doc(uid).set(user.toMap());
      if (!mounted) return '';
      Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false);
      showAlertDialog(
          context: context,
          message: "Informations utilisateur mises à jour avec succès !");
    } catch (e) {
      showAlertDialog(
          context: context,
          message:
              "Échec de la sauvegarde des informations utilisateur : ${e.toString()}");
    }

    return profileImageUrl;
  }

  void updateUserPresence() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("No authenticated user, skipping presence update.");
      return;
    }

    final uid = currentUser.uid;
    final connectedRef = FirebaseDatabase.instance.ref('.info/connected');

    connectedRef.onValue.listen((event) async {
      final isConnected = event.snapshot.value as bool? ?? false;

      channel.sink.add(jsonEncode({
        'userId': uid,
        'isOnline': isConnected,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      }));
    });

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'pong') {
        print('Received pong from server');
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    });
  }

  Future<UserModel?> getCurrentUserInfo() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    final userDoc = await firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return UserModel.fromMap(userDoc.data()!);
    }
    return null;
  }

  void setUserState(bool isOnline) async {
    await firestore.collection('users').doc(auth.currentUser!.uid).update({
      'active': isOnline,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void dispose() {
    channel.sink.close();
  }
}
