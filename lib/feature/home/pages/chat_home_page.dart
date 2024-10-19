import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/models/group.dart';
import 'package:tuyage/common/models/last_message_model.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/routes/routes.dart';
import 'package:tuyage/common/utils/coloors.dart';
import 'package:tuyage/feature/chat/controller/chat_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHomePage extends ConsumerWidget {
  const ChatHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var firebaseUser = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<List<Group>>(
              stream: ref.watch(chatControllerProvider).chatGroups(),
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Coloors.greenDark,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Container(),
                  );
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final groupData = snapshot.data![index];
                    return ListTile(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.chat,
                          arguments: {
                            'name': groupData.name, // Nom du groupe
                            'uid': groupData.groupId, // Identifiant du groupe
                            'isGroupChat':
                                true, // Indicateur si c'est un chat de groupe
                            'profileImage':
                                groupData.groupPic, // Image du groupe
                            'lastSeen':
                                0, // Pour les groupes, on peut mettre une valeur fixe ou ne pas passer cette info
                            'user':
                                null, // Pour un groupe, il n'y a pas d'utilisateur unique
                          },
                        );
                      },
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(groupData.name),
                          Text(
                            DateFormat.Hm().format(groupData.timeSent),
                            style: TextStyle(
                              fontSize: 13,
                              color: context.theme.greyColor,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          groupData.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.theme.greyColor),
                        ),
                      ),
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: groupData.groupPic,
                              placeholder: (context, url) => CircleAvatar(
                                radius: 24,
                                backgroundColor: context.theme.greyColor,
                                child: const CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  CircleAvatar(
                                radius: 24,
                                backgroundColor: context.theme.greyColor,
                                child: const Icon(
                                  Icons.person,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                radius: 24,
                                backgroundImage: imageProvider,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<List<LastMessageModel>>(
              stream: ref.watch(chatControllerProvider).getAllLastMessageList(),
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Coloors.greenDark,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Container(),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final lastMessageData = snapshot.data![index];

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(lastMessageData.contactId)
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return Center(
                            child: Text(
                                'no user get with ${lastMessageData.contactId} mais on avait trouve ${lastMessageData.lastMessage}'),
                          );
                        }

                        final user = UserModel(
                          username: lastMessageData.username,
                          uid: lastMessageData.contactId,
                          profileImageUrl: lastMessageData.profileImageUrl,
                          active: userSnapshot.data!.get('active'),
                          lastSeen: userSnapshot.data!.get('lastSeen') ?? 0,
                          phoneNumber: '0',
                          groupId: [],
                          email: lastMessageData.email,
                        );

                        final displayUsername = user.uid == firebaseUser!.uid
                            ? '${user.username} (You)'
                            : user.username;

                        return ListTile(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.chat,
                              arguments: {
                                'name': user.username, // Nom de l'utilisateur
                                'uid': user
                                    .uid, // Identifiant unique de l'utilisateur
                                'isGroupChat': false, // Ce n'est pas un groupe
                                'profileImage': user
                                    .profileImageUrl, // Image de l'utilisateur
                                'lastSeen': user.lastSeen, // Dernière activité
                                'user': user, // Objet complet de l'utilisateur
                              },
                            );
                          },
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(displayUsername),
                              Text(
                                DateFormat.Hm()
                                    .format(lastMessageData.timeSent),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.theme.greyColor,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              "${lastMessageData.lastMessage} status",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.theme.greyColor),
                            ),
                          ),
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user.profileImageUrl ??
                                      '', // Utilise une chaîne vide si l'URL est nulle
                                  placeholder: (context, url) => const SizedBox(
                                    width:
                                        48, // Ajuste la taille selon tes besoins
                                    height:
                                        48, // Ajuste la taille selon tes besoins
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    width:
                                        48, // Ajuste la taille selon tes besoins
                                    height:
                                        48, // Ajuste la taille selon tes besoins
                                    child: Icon(
                                      Icons.person,
                                      size: 24,
                                      color: context.theme.greyColor,
                                    ),
                                  ),
                                  fit: BoxFit
                                      .cover, // Assure que l'image remplit bien le cercle
                                  width:
                                      48, // Ajuste la taille selon tes besoins
                                  height:
                                      48, // Ajuste la taille selon tes besoins
                                ),
                              ),
                              if (user.active)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              if (!user.active)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 255, 178, 178),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 209, 12, 12),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
