import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/models/status_model.dart';
import 'package:tuyage/feature/auth/controller/auth_controller.dart';
import 'package:tuyage/feature/status/repository/status_repository.dart';

final statusControllerProvider = Provider((ref) {
  final statusRepository = ref.read(statusRepositoryProvider);
  return StatusController(
    ref: ref,
    statusRepository: statusRepository,
  );
});

class StatusController {
  final StatusRepository statusRepository;
  final ProviderRef ref;

  StatusController({required this.ref, required this.statusRepository});

  Future<void> addStatus(File file, BuildContext context) async {
    ref.watch(userInfoAuthProvider).whenData((value) {
      statusRepository.uploadStatus(
        username: value!.username,
        profilePic: value.profileImageUrl ?? '',
        phoneNumber: value.phoneNumber,
        statusImage: file,
        context: context,
      );
    });
  }

  Future<List<Status>> getStatus(BuildContext context) async {
    List<Status> statuses = await statusRepository.getStatus(context);
    return statuses;
  }
}
