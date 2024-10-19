import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/utils/coloors.dart';
import 'package:tuyage/common/widgets/custom_elevated_button.dart';
import 'package:tuyage/common/widgets/custom_icon_button.dart';
import 'package:tuyage/feature/auth/controller/auth_controller.dart';
import 'package:tuyage/feature/auth/widgets/custom_text_field.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController usernameController;
  late TextEditingController phoneNumberController;
  late TextEditingController countryNameController;
  late TextEditingController countryCodeController;

  showCountryPickerBottomSheet() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: ['BI'],
      countryListTheme: CountryListThemeData(
        bottomSheetHeight: 600,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        flagSize: 22,
        borderRadius: BorderRadius.circular(20),
        textStyle: TextStyle(color: context.theme.greyColor),
        inputDecoration: InputDecoration(
          labelStyle: TextStyle(color: context.theme.greyColor),
          prefixIcon: const Icon(
            Icons.language,
            color: Coloors.greenDark,
          ),
          hintText: 'Rondera igihugu ukoresheje code canke izina',
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: context.theme.greyColor!.withOpacity(.2),
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: Coloors.greenDark,
            ),
          ),
        ),
      ),
      onSelect: (country) {
        countryNameController.text = country.name;
        countryCodeController.text = country.phoneCode;
      },
    );
  }

  @override
  void initState() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    usernameController = TextEditingController();
    phoneNumberController = TextEditingController();
    countryNameController = TextEditingController(text: 'Burundi');
    countryCodeController = TextEditingController(text: '257');
    super.initState();
  }

  signup() {
    final email = emailController.text;
    final password = passwordController.text;
    final username = usernameController.text;
    final phoneNumber = phoneNumberController.text;
    final countryCode = countryCodeController.text;

    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      return showAlertDialog(
        context: context,
        message: "Please enter all fields.",
      );
    }

    ref.read(authControllerProvider).signupWithEmailAndPassword(
          context: context,
          email: email,
          password: password,
          username: username,
          phoneNumber: phoneNumber,
          ref: ref,
          countryCode: countryCode,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Signup",
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
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'Turagusavye Winjize Infos zawe zukuri. ',
                style: TextStyle(
                  color: context.theme.greyColor,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: CustomTextField(
              onTap: showCountryPickerBottomSheet,
              controller: countryNameController,
              readOnly: true,
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
                color: Coloors.greenDark,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: CustomTextField(
                        onTap: showCountryPickerBottomSheet,
                        controller: countryCodeController,
                        prefixText: '+',
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        controller: phoneNumberController,
                        hintText: 'Numero ya phone yawe',
                        textAlign: TextAlign.left,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: emailController,
                  hintText: 'Email yawe',
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: usernameController,
                  hintText: 'Username yawe',
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: passwordController,
                  hintText: 'Password yawe',
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Carrier charges may apply',
            style: TextStyle(
              color: context.theme.greyColor,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: CustomElevetedButton(
        onPressed: signup,
        text: 'Signup',
        buttonWidth: 100,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    phoneNumberController.dispose();
    countryNameController.dispose();
    countryCodeController.dispose();
    super.dispose();
  }
}
