import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/utils/coloors.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.contactSource,
    required this.onTap,
    required this.isPhoneContact,
  });

  final UserModel contactSource;
  final VoidCallback onTap;
  final bool isPhoneContact;

  @override
  Widget build(BuildContext context) {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    final displayUsername = contactSource.uid == firebaseUser!.uid
        ? '${contactSource.username} (You)'
        : contactSource.username;
    final displaySubtitle = contactSource.uid == firebaseUser.uid
        ? 'Wiyandikire wewe nyene'
        : "Bite ubu nsigaye nkoresha Tuyage Barundi";
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.only(
        left: 20,
        right: 10,
      ),
      leading: CircleAvatar(
        backgroundColor: context.theme.greyColor!.withOpacity(0.3),
        radius: 20,
        backgroundImage: contactSource.profileImageUrl!.isNotEmpty
            ? CachedNetworkImageProvider(contactSource.profileImageUrl ?? '')
            : null,
        child: contactSource.profileImageUrl!.isEmpty
            ? const Icon(
                Icons.person,
                size: 30,
                color: Colors.white,
              )
            : null,
      ),
      title: Text(
        displayUsername,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: contactSource.profileImageUrl!.isEmpty
          ? null
          : Text(
              displaySubtitle,
              style: TextStyle(
                color: context.theme.greyColor,
                fontWeight: FontWeight.w600,
              ),
            ),
      trailing:
          isPhoneContact // Affiche le bouton uniquement si c'est un contact téléphonique
              ? TextButton(
                  onPressed: onTap,
                  style:
                      TextButton.styleFrom(foregroundColor: Coloors.greenDark),
                  child: const Text('MUTUMIRE'),
                )
              : null,
    );
  }
}
