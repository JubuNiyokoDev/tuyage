import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/common/routes/routes.dart';
import 'package:tuyage/common/widgets/custom_icon_button.dart';
import 'package:tuyage/feature/auth/controller/auth_controller.dart';
import 'package:tuyage/feature/auth/repository/auth_repository.dart';
import 'package:tuyage/feature/chat/controller/chat_controller.dart';
import 'package:tuyage/feature/home/pages/call_home_page.dart';
import 'package:tuyage/feature/home/pages/chat_home_page.dart';
import 'package:tuyage/feature/home/pages/status_home_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late TabController tabBarController;

  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    tabBarController = TabController(length: 3, vsync: this);
    loadUserInfo();
    WidgetsBinding.instance.addObserver(this);
    ref.read(authControllerProvider).updateUserPresence();
  }

  Future<void> loadUserInfo() async {
    var firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data();
        setState(() {
          currentUser = UserModel.fromMap(userData!);
          isLoading = false;
        });
        ref.read(chatControllerProvider).monitorNetworkStatus(context, false);
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(authControllerProvider).setUserState(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        ref.read(authControllerProvider).setUserState(false);
        break;
    }
  }

  @override
  void dispose() {
    ref.read(authRepositoryProvider).dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Tuyage Barundi',
                    style: TextStyle(letterSpacing: 1)),
                elevation: 1,
                actions: [
                  CustomIconButton(onPressed: () {}, icon: Icons.search),
                  PopupMenuButton(
                      itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text(
                                'Groupe Nshasha',
                              ),
                              onTap: () => Future(
                                () => Navigator.pushNamed(
                                  context,
                                  Routes.createGroup,
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              child: const Text('Broadcast Nshasha'),
                              onTap: () {},
                            ),
                            PopupMenuItem(
                              child: const Text(
                                'Fatanya Devices Zawe',
                              ),
                              onTap: () {},
                            ),
                            PopupMenuItem(
                              child: const Text(
                                'Message ziri muri Favorie',
                              ),
                              onTap: () {},
                            ),
                            PopupMenuItem(
                              child: const Text(
                                'Kora Setting',
                              ),
                              onTap: () {},
                            ),
                          ]),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Future.delayed(Duration.zero, () {
                          showMenu<String>(
                            context: context,
                            position: RelativeRect.fromLTRB(
                              MediaQuery.of(context).size.width - 150,
                              kToolbarHeight,
                              0,
                              0,
                            ),
                            items: [
                              PopupMenuItem<String>(
                                enabled: false,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundImage:
                                          currentUser?.profileImageUrl != null
                                              ? CachedNetworkImageProvider(
                                                  currentUser!.profileImageUrl!)
                                              : null,
                                      backgroundColor: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                        currentUser?.username ?? 'Utilisateur'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'add_account',
                                child: Row(
                                  children: [
                                    Icon(Icons.add, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Ajouter un autre compte'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Se déconnecter'),
                                  ],
                                ),
                              ),
                            ],
                          ).then((value) {
                            if (value == 'logout') {
                              ref
                                  .read(authControllerProvider)
                                  .logout(context, currentUser!);
                            } else if (value == 'add_account') {
                              showAlertDialog(
                                context: context,
                                message: "Vuba iraza",
                              );
                            }
                          });
                        });
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            (currentUser?.profileImageUrl != null &&
                                    currentUser!.profileImageUrl!.isNotEmpty)
                                ? CachedNetworkImageProvider(
                                    currentUser!.profileImageUrl!)
                                : null,
                        child: (currentUser?.profileImageUrl == null ||
                                currentUser!.profileImageUrl!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 18,
                                color: context.theme.greyColor,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
                bottom: TabBar(
                  controller: tabBarController,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  splashFactory: NoSplash.splashFactory,
                  tabs: const [
                    Tab(text: 'Chat zanje'),
                    Tab(text: 'Status Zanje'),
                    Tab(text: 'Calls Zanje'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: tabBarController,
                children: const [
                  ChatHomePage(),
                  StatusHomePage(),
                  CallHomePage(),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  if (tabBarController.index == 0) {
                    Navigator.pushNamed(context, Routes.contact);
                  } else {
                    File? pickedImage = await pickImageFromGallery(context);
                    if (pickedImage != null) {
                      Navigator.pushNamed(
                        context,
                        Routes.status,
                        arguments: pickedImage,
                      );
                    } else {
                      showAlertDialog(
                          context: context, message: "No image selected.");
                    }
                  }
                },
                child: const Icon(Icons.chat),
              ),
            ),
          );
  }
}
