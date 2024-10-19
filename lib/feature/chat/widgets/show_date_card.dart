import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';

class ShowDateCard extends StatelessWidget {
  const ShowDateCard({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: context.theme.receiverChatCardBg,
      ),
      child: Text(
        DateFormat.yMMMd().format(date),
      ),
    );
  }
}
