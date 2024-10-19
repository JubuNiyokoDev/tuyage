import 'package:flutter/material.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/routes/routes.dart';
import 'package:tuyage/common/widgets/custom_elevated_button.dart';
import 'package:tuyage/feature/welcome/widgets/language_button.dart';
import 'package:tuyage/feature/welcome/widgets/privacy_and_terms.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void navigationToLoginPage(BuildContext context) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  void navigationToSignupPage(BuildContext context) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.signup, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                child: Image.asset(
                  'assets/images/circle.png',
                  color: context.theme.circleImageColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Column(
              children: [
                const Text(
                  "Urakaza Neza Kuri Tuyage Burundi",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const PrivacyAndTerms(),
                CustomElevetedButton(
                  onPressed: () => navigationToLoginPage(context),
                  text: "NEMEYE REKA MBANDANYE",
                ),
                const SizedBox(height: 20),
                CustomElevetedButton(
                  onPressed: () => navigationToSignupPage(context),
                  text: "FUNGURA AKANTO KANDI",
                ),
                const SizedBox(height: 40),
                const LanguageButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
