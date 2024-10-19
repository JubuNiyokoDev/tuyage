import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/widgets/custom_elevated_button.dart';
import 'package:tuyage/common/widgets/custom_icon_button.dart';
import 'package:tuyage/feature/auth/controller/auth_controller.dart';
import 'package:tuyage/feature/auth/pages/image_picker_page.dart';
import 'package:tuyage/feature/auth/widgets/custom_text_field.dart';

class UserInfoPage extends ConsumerStatefulWidget {
  const UserInfoPage({super.key, required this.user});
  final UserModel user;

  @override
  ConsumerState<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends ConsumerState<UserInfoPage> {
  File? imageCamera;
  Uint8List? imageGallery;
  late TextEditingController usernameController;

  @override
  void initState() {
    super.initState();
    usernameController =
        TextEditingController(text: widget.user.username ?? '');
  }

  Future<void> saveUserDataToFirebase() async {
    String username = usernameController.text;

    if (username.isEmpty) {
      return showAlertDialog(context: context, message: "Shiramwo username");
    } else if (username.length < 3 || username.length > 20) {
      return showAlertDialog(
          context: context, message: "Username itegerezwa kuba iri muri 3-20");
    }

    // Affichage du dialogue de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final profileImageUrl =
          await ref.read(authControllerProvider).saveUserInfoToFirestore(
                username: username,
                profileImage: imageCamera ??
                    imageGallery ??
                    widget.user.profileImageUrl ??
                    '',
                context: context,
                mounted: mounted,
                email: widget.user.email,
                phoneNumber: widget.user.phoneNumber,
                ref: ref,
              );
      print(profileImageUrl);
      // Fermer la boîte de dialogue de chargement
      Navigator.of(context).pop();
    } catch (e) {
      // En cas d'erreur, fermer la boîte de dialogue et afficher l'erreur
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      showAlertDialog(
          context: context,
          message: "Failed to save user information: ${e.toString()}");
    }
  }

  Future<void> pickImageFromCamera() async {
    Navigator.of(context).pop();
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return;

      // Remplacer l'image précédente
      setState(() {
        imageCamera = File(image.path);
        imageGallery = null;
      });
    } catch (e) {
      showAlertDialog(context: context, message: e.toString());
    }
  }

  void imagePickerTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 20),
                const Text(
                  "Ifoto ya Profile",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                CustomIconButton(
                    onPressed: () => Navigator.pop(context), icon: Icons.close),
                const SizedBox(width: 15),
              ],
            ),
            Divider(color: context.theme.greyColor!.withOpacity(0.3)),
            const SizedBox(height: 5),
            Row(
              children: [
                const SizedBox(width: 20),
                imagePickerIcon(
                  onTap: pickImageFromCamera,
                  icon: Icons.camera_alt_rounded,
                  text: 'Camera',
                ),
                const SizedBox(width: 15),
                imagePickerIcon(
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ImagePickerPage()),
                    );
                    if (image == null) return;

                    // Remplacer l'image précédente
                    setState(() {
                      imageGallery = image;
                      imageCamera = null;
                    });
                  },
                  icon: Icons.photo_camera_back_rounded,
                  text: 'Gallery',
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        );
      },
    );
  }

  Widget imagePickerIcon(
      {required VoidCallback onTap,
      required IconData icon,
      required String text}) {
    return Column(
      children: [
        CustomIconButton(
          onPressed: onTap,
          icon: icon,
          iconColor: Colors.green,
          minWidth: 50,
        ),
        const SizedBox(height: 5),
        Text(text, style: TextStyle(color: context.theme.greyColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Info za Profile',
            style: TextStyle(color: context.theme.authAppbarTextColor)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 60),
        child: Column(
          children: [
            Text(
              'Please provide your name and an optional profile photo',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.theme.greyColor),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: imagePickerTypeBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.theme.photoIconBgColor,
                  border: Border.all(
                    color: imageCamera == null && imageGallery == null
                        ? Colors.transparent
                        : context.theme.greyColor!.withOpacity(.4),
                  ),
                  image: imageCamera != null ||
                          imageGallery != null ||
                          widget.user.profileImageUrl != null
                      ? DecorationImage(
                          fit: BoxFit.cover,
                          image: imageGallery != null
                              ? MemoryImage(imageGallery!)
                              : widget.user.profileImageUrl != null
                                  ? NetworkImage(widget.user.profileImageUrl!)
                                  : FileImage(imageCamera!) as ImageProvider,
                        )
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3, right: 3),
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    size: 48,
                    color: imageCamera == null &&
                            imageGallery == null &&
                            widget.user.profileImageUrl == null
                        ? context.theme.photoIconColor
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: CustomTextField(
                    controller: usernameController,
                    hintText: 'Type your name here',
                    textAlign: TextAlign.start,
                    autFocus: true,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.emoji_emotions_outlined,
                    color: context.theme.photoIconColor),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: CustomElevetedButton(
        onPressed: saveUserDataToFirebase,
        text: "EMEZA",
        buttonWidth: 100,
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }
}
