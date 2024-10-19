import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/feature/group/repository/group_repository.dart';
import 'package:tuyage/common/models/group.dart' as model;

final groupeControllerProvider = Provider((ref) {
  final groupRepository = ref.read(groupRepositoryProvider);
  return GroupController(
    groupRepository: groupRepository,
    ref: ref,
  );
});

class GroupController {
  final GroupRepository groupRepository;
  final ProviderRef ref;

  GroupController({
    required this.groupRepository,
    required this.ref,
  });

  void createGroup(BuildContext context, String name, File? groupPic,
      List<UserModel> selectedContact) {
    groupRepository.createGroup(context, name, groupPic, selectedContact);
  }

  Future<model.Group?> getGroupById(String groupId) async {
    return await groupRepository.getGroupById(groupId);
  }
}
