import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/feature/contact/controller/contacts_controller.dart';

final selectedGroupContacts = StateProvider<List<UserModel>>((ref) => []);

class SelectContactsGroup extends ConsumerStatefulWidget {
  const SelectContactsGroup({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SelectContactsGroupState();
}

class _SelectContactsGroupState extends ConsumerState<SelectContactsGroup> {
  List<int> selectedContactIndex = [];

  void selectContact(int index, UserModel contact) {
    if (selectedContactIndex.contains(index)) {
      selectedContactIndex.remove(index);
    } else {
      selectedContactIndex.add(index);
    }
    setState(() {});
    ref
        .read(selectedGroupContacts.state)
        .update((state) => [...state, contact]);
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(contactsControllerProvider).when(
          data: (contactList) => Expanded(
            child: ListView.builder(
                itemCount: contactList[0].length,
                itemBuilder: (context, index) {
                  final contact = contactList[0][index];
                  return InkWell(
                    onTap: () => selectContact(index, contact),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          contact.username,
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        leading: selectedContactIndex.contains(index)
                            ? IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.done),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
          ),
          error: (e, t) {
            return const SizedBox();
          },
          loading: () {
            return Center(
              child: CircularProgressIndicator(
                color: context.theme.authAppbarTextColor,
              ),
            );
          },
        );
  }
}
