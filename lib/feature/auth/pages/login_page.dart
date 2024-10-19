import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/widgets/custom_elevated_button.dart';
import 'package:tuyage/common/widgets/custom_icon_button.dart';
import 'package:tuyage/feature/auth/controller/auth_controller.dart';
import 'package:tuyage/feature/auth/widgets/custom_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    super.initState();
  }

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      return showAlertDialog(
        context: context,
        message: "Please enter both email and password.",
      );
    }

    ref.read(authControllerProvider).loginWithEmailAndPassword(
          context: context,
          email: email,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Login",
          style: TextStyle(
            color: context.theme.authAppbarTextColor,
          ),
        ),
        centerTitle: true,
        actions: [
          CustomIconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icons.login,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Please log in with your email and password.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.theme.greyColor,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: CustomTextField(
              controller: emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: CustomTextField(
              controller: passwordController,
              hintText: 'Password',
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: CustomElevetedButton(
        onPressed: login,
        text: 'Login',
        buttonWidth: 100,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
