import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/routes/routes.dart';
import 'package:tuyage/common/utils/coloors.dart';
import 'package:tuyage/common/widgets/custom_icon_button.dart';
import 'package:tuyage/feature/contact/controller/contacts_controller.dart';
import 'package:tuyage/feature/contact/widgets/contact_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends ConsumerWidget {
  const ContactPage({super.key});

  Future<void> shareEmailLink(String emailAddress) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      query:
          'subject=Rejoins-nous sur Tuyage Barundi!&body=Ingo twiyagire kuri Tuyage Barundi kuko iranyaruka cane kandi nikubuntu vyose!',
    );

    if (await launchUrl(emailLaunchUri)) {
      // Email client opened successfully
    } else {
      // Error handling
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cagura contact",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            ref.watch(contactsControllerProvider).when(
              data: (allContacts) {
                return Text(
                  "${allContacts[0].isEmpty ? 'No contacts' : 'contacts'} ${allContacts[0].length}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                );
              },
              error: (e, t) {
                return const SizedBox();
              },
              loading: () {
                return const Text(
                  'Rindira.... ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          CustomIconButton(onPressed: () {}, icon: Icons.search),
          CustomIconButton(onPressed: () {}, icon: Icons.more_vert),
        ],
      ),
      body: ref.watch(contactsControllerProvider).when(
        data: (allContacts) {
          return ListView.builder(
            itemCount: allContacts[0].length + allContacts[1].length,
            itemBuilder: (context, index) {
              late UserModel contact;
              bool isPhoneContact =
                  false; // Par défaut, ce n'est pas un contact téléphonique

              if (index < allContacts[0].length) {
                contact = allContacts[0][index];
                isPhoneContact =
                    false; // Contacts Firebase ne sont pas des contacts téléphoniques
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index == 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          myListTile(
                            leading: Icons.group,
                            text: "Groupe nshahsa",
                          ),
                          myListTile(
                            leading: Icons.contacts,
                            text: "Umunywanyi musha",
                            trailing: Icons.qr_code,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Text(
                              "Abanywanyi ba Tuyage Barundi",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.theme.greyColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ContactCard(
                      contactSource: contact,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          Routes.chat,
                          arguments: {
                            'name': contact.username,
                            'uid': contact.uid,
                            'isGroupChat': false,
                            'profileImage': contact.profileImageUrl,
                            'lastSeen': contact.lastSeen,
                            'user': contact,
                          },
                        );
                      },
                      isPhoneContact: isPhoneContact,
                    ),
                  ],
                );
              } else {
                contact = allContacts[1][index - allContacts[0].length];
                isPhoneContact = true;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index == allContacts[0].length)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          "Tumira Kuri Tuyage Barundi",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.theme.greyColor,
                          ),
                        ),
                      ),
                    ContactCard(
                      contactSource: contact,
                      onTap: () => shareEmailLink(contact.email),
                      isPhoneContact: isPhoneContact,
                    ),
                  ],
                );
              }
            },
          );
        },
        error: (e, t) {
          return null;
        },
        loading: () {
          return Center(
            child: CircularProgressIndicator(
              color: context.theme.authAppbarTextColor,
            ),
          );
        },
      ),
    );
  }

  ListTile myListTile({
    required IconData leading,
    required String text,
    IconData? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(top: 10, left: 20, right: 10),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Coloors.greenDark,
        child: Icon(
          leading,
          color: Colors.white,
        ),
      ),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        trailing,
        color: Coloors.greyDark,
      ),
    );
  }
}
