import 'dart:io';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:tuyage/common/models/status_model.dart';
import 'package:tuyage/common/models/user_model.dart';
import 'package:tuyage/feature/auth/pages/login_page.dart';
import 'package:tuyage/feature/auth/pages/signup_page.dart';
import 'package:tuyage/feature/auth/pages/user_info_page.dart';
import 'package:tuyage/feature/chat/pages/chat_page.dart';
import 'package:tuyage/feature/chat/pages/profile_page.dart';
import 'package:tuyage/feature/contact/pages/contact_page.dart';
import 'package:tuyage/feature/group/screens/create_group_screen.dart';
import 'package:tuyage/feature/group/screens/groupe_profile.dart';
import 'package:tuyage/feature/home/pages/home_page.dart';
import 'package:tuyage/feature/status/screens/confirm_status_screen.dart';
import 'package:tuyage/feature/status/screens/status_screen.dart';
import 'package:tuyage/feature/welcome/pages/welcome_page.dart';

class Routes {
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String verification = 'verification';
  static const String userInfo = 'user-info';
  static const String home = 'home';
  static const String contact = 'contact';
  static const String chat = 'chat';
  static const String profile = 'profile';
  static const String groupProfile = 'groupProfile';
  static const String status = 'confirm-status-screen';
  static const String statusScreen = 'status-screen';
  static const String createGroup = 'create-group';

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) => const Scaffold(
        body: Center(
          child: Text("Erreur : Type d'argument incorrect."),
        ),
      ),
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(
          builder: (context) => const WelcomePage(),
        );
      case login:
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
        );
      case signup:
        return MaterialPageRoute(
          builder: (context) => const SignupPage(),
        );
      case userInfo:
        if (settings.arguments is UserModel) {
          final UserModel user = settings.arguments as UserModel;
          return MaterialPageRoute(
            builder: (context) => UserInfoPage(user: user),
          );
        }
        return _errorRoute();
      case home:
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
        );
      case status:
        if (settings.arguments is File) {
          final file = settings.arguments as File;
          return MaterialPageRoute(
            builder: (context) => ConfirmStatusScreen(file: file),
          );
        }
        return _errorRoute();
      case statusScreen:
        if (settings.arguments is Status) {
          final status = settings.arguments as Status;
          return MaterialPageRoute(
            builder: (context) => StatusScreen(status: status),
          );
        }
        return _errorRoute();
      case contact:
        return MaterialPageRoute(
          builder: (context) => const ContactPage(),
        );
      case chat:
        if (settings.arguments is Map<String, dynamic>) {
          final arguments = settings.arguments as Map<String, dynamic>;
          final String name = arguments['name'];
          final String uid = arguments['uid'];
          final String profileImage = arguments['profileImage'];
          final bool isGroupChat = arguments['isGroupChat'];
          final int? lastSeen = arguments['lastSeen'];
          final UserModel? user = arguments['user'];

          return MaterialPageRoute(
            builder: (context) => ChatPage(
              name: name,
              uid: uid,
              isGroupChat: isGroupChat,
              profileImage: profileImage,
              lastSeen: lastSeen,
              user: user,
            ),
          );
        }
        return _errorRoute();
      case profile:
        if (settings.arguments is UserModel) {
          final user = settings.arguments as UserModel;
          return PageTransition(
            child: UserProfilePage(user: user),
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 800),
          );
        }
        return _errorRoute();
      case groupProfile:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final groupName = args['groupName'] as String;
          final uid = args['uid'] as String;

          return PageTransition(
            child: GroupProfilePage(
              groupName: groupName,
              uid: uid,
            ),
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 800),
          );
        }
        return _errorRoute();
      case createGroup:
        return MaterialPageRoute(
            builder: (context) => const CreateGroupScreen());
      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text("Nta Route Yigeze Ibonwa"),
            ),
          ),
        );
    }
  }
}
