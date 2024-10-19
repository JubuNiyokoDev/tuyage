import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/feature/contact/repository/contact_repository.dart';

final contactsControllerProvider = FutureProvider(
  (ref) {
    final contactsRepository = ref.watch(contactsRepositoryProvider);
    return contactsRepository.getAllContacts();
  },
);
