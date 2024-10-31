import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/utils/coloors.dart';
import 'package:tuyage/feature/status/controller/status_controller.dart';
import 'package:tuyage/common/helper/show_loading_dialog.dart';

class ConfirmStatusScreen extends ConsumerWidget {
  final File file;

  const ConfirmStatusScreen({super.key, required this.file});

  Future<void> addStatus(WidgetRef ref, BuildContext context) async {
    try {
      showLoadingDialog(context: context, message: "Uploading status...");

      await ref.read(statusControllerProvider).addStatus(file, context);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      showAlertDialog(context: context, message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Image.file(file),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addStatus(ref, context),
        backgroundColor: Coloors.greenDark,
        child: const Icon(Icons.done),
      ),
    );
  }
}
