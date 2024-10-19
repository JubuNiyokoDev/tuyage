import 'package:flutter/material.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';

class PrivacyAndTerms extends StatelessWidget {
  const PrivacyAndTerms({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: "Soma ",
          style: TextStyle(
            color: context.theme.greyColor,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: 'Amategeko Yacu ',
              style: TextStyle(
                color: context.theme.blueColor,
              ),
            ),
            const TextSpan(
              text: 'Hama Fyonda "Nemeye Reka Mbandanye" kugira wemere ',
            ),
            TextSpan(
              text: 'Amategeko Ya services zacu',
              style: TextStyle(
                color: context.theme.blueColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
