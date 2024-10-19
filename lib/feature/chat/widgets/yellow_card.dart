import 'package:flutter/material.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';

class YellowCard extends StatelessWidget {
  const YellowCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 30,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.theme.yellowCardBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "Message and call are end-to-end encrypted.No one outside of this chat ,not even Tuyage Barundi,can read or listen to them.Tap to learn more.",
          style: TextStyle(
            fontSize: 13,
            color: context.theme.yellowCardTextColor,
          ),
          textAlign: TextAlign.center,
        ));
  }
}