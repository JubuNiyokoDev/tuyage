import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';

showAlertDialog({
  required BuildContext context,
  required String message,
  String? btnText,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Text(
          message,
          style: TextStyle(
            color: context.theme.greyColor,
            fontSize: 15,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              btnText ?? "SAWA",
              style: TextStyle(
                color: context.theme.circleImageColor,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<File?> pickImageFromGallery(BuildContext context) async {
  File? image;
  try {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      image = File(pickedImage.path);
    } else {
      print("$image");
    }
  } catch (e) {
    showAlertDialog(context: context, message: e.toString());
  }
  return image;
}
