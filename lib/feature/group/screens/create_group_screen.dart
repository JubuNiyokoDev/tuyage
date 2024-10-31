import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/feature/group/controller/group_controller.dart';
import 'package:tuyage/feature/group/widgets/select_contacts_group.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupeScreen();
}

class _CreateGroupeScreen extends ConsumerState<CreateGroupScreen> {
  final TextEditingController groupNameController = TextEditingController();
  File? image;
  void selectImage() async {
    image = await pickImageFromGallery(context);
    setState(() {});
  }

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }

  void createGroup() {
    if (groupNameController.text.trim().isNotEmpty) {
      ref.read(groupeControllerProvider).createGroup(
            context,
            groupNameController.text.trim(),
            image,
            ref.read(selectedGroupContacts),
          );
      ref.read(selectedGroupContacts.state).update((state) => []);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Groupe Nshasha',
          style: TextStyle(
            color: context.theme.authAppbarTextColor,
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Stack(
              children: [
                image == null
                    ? CircleAvatar(
                        radius: 64,
                        child: Icon(
                          Icons.person,
                          color: context.theme.greyColor,
                        ),
                      )
                    : CircleAvatar(
                        backgroundImage: FileImage(
                          image!,
                        ),
                        radius: 64,
                      ),
                Positioned(
                  bottom: -10,
                  left: 80,
                  child: IconButton(
                    onPressed: selectImage,
                    icon: const Icon(
                      Icons.add_a_photo,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: groupNameController,
                decoration: const InputDecoration(
                  hintText: 'Izina rya groupe',
                ),
              ),
            ),
            const Text(
              'Cagura umunywanyi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SelectContactsGroup(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createGroup,
        backgroundColor: context.theme.authAppbarTextColor,
        child: const Icon(
          Icons.done,
          color: Colors.white,
        ),
      ),
    );
  }
}
