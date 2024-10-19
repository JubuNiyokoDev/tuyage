import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/helper/show_loading_dialog.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/routes/routes.dart';
import 'package:tuyage/feature/auth/repository/auth_repository.dart';

final authControllerProvider = Provider(
  (ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    return AuthController(
      authRepository: authRepository,
      ref: ref,
    );
  },
);

final userInfoAuthProvider = StreamProvider<UserModel?>((ref) {
  final authController = ref.watch(authControllerProvider);
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    return Stream.value(null);
  }

  final uid = currentUser.uid;

  return authController.getUserById(uid);
});

class AuthController {
  final AuthRepository authRepository;
  final ProviderRef ref;

  AuthController({required this.authRepository, required this.ref});

  Stream<UserModel?> getUserById(String uid) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Stream.value(null);
    }
    return authRepository.getUserById(uid);
  }

  Stream<ConnectivityResult> getUserPresenceStatus({required String uid}) {
    return authRepository.getUserPresenceStatus(uid: uid);
  }

  Future<void> updateUserPresence() async {
    return authRepository.updateUserPresence();
  }

  Future<void> updateUserPresenceToOffline(
      String? uid, BuildContext context) async {
    if (uid != null) {
      await authRepository.updateUserPresenceToOffline(context, uid);
    }
  }

  Future<UserModel?> getCurrentUserInfo() async {
    return await authRepository.getCurrentUserInfo();
  }

  saveUserInfoToFirestore({
    required String username,
    required var profileImage,
    required BuildContext context,
    required bool mounted,
    required String email,
    required WidgetRef ref,
    required String phoneNumber,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      showAlertDialog(
        context: context,
        message: "Vous devez être connecté pour sauvegarder vos informations.",
      );
      return;
    }

    await authRepository.saveUserInfoToFirestore(
      username: username,
      profileImage: profileImage,
      context: context,
      mounted: mounted,
      email: email,
      ref: ref,
      phoneNumber: phoneNumber,
    );
  }

  void signupWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required WidgetRef ref,
    required String countryCode,
  }) {
    authRepository.signupWithEmailAndPassword(
      context: context,
      email: email,
      password: password,
      username: username,
      ref: ref,
      phoneNumber: phoneNumber,
      countryCode: countryCode,
    );
  }

  void loginWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String password,
  }) {
    authRepository.loginWithEmailAndPassword(
      context: context,
      email: email,
      password: password,
    );
  }

  void logout(BuildContext context, UserModel user) async {
    try {
      showLoadingDialog(
        context: context,
        message: 'Déconnexion en cours...',
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          await updateUserPresenceToOffline(uid, context);
          print('User $uid set to offline');
        } catch (e) {
          print('Erreur lors de la mise à jour du statut utilisateur: $e');
        }
      }

      // Déconnexion de Firebase
      await FirebaseAuth.instance.signOut();
      print('FirebaseAuth signed out');

      // Effacer le cache des images
      if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
        try {
          await CachedNetworkImage.evictFromCache(user.profileImageUrl!);
        } catch (cacheError) {
          print("Erreur lors de l'effacement du cache : $cacheError");
        }
      }

      // Effacer les préférences partagées
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (prefsError) {
        print("Erreur lors de l'effacement des préférences : $prefsError");
      }

      // Fermer la boîte de dialogue de chargement
      Navigator.of(context).pop();

      // Naviguer vers la page de connexion et retirer toutes les routes précédentes
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.login,
        (route) => false,
      );
    } catch (e) {
      Navigator.of(context).pop();
      showAlertDialog(
        context: context,
        message: "Échec de la déconnexion : ${e.toString()}",
      );
    }
  }

  void setUserState(bool isOnline) {
    return authRepository.setUserState(isOnline);
  }
}
