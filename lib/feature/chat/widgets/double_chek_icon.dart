import 'package:flutter/material.dart';

class DoubleCheckIcon extends StatelessWidget {
  final bool isSeen; // true for seen, false for not seen
  final bool isDelivered; // true for delivered, false for not delivered

  const DoubleCheckIcon({
    super.key,
    required this.isSeen,
    required this.isDelivered,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Bottom check icon (first check)
        if (isDelivered)
          const Icon(
            Icons.check,
            color: Colors.grey,
            size: 20,
          ),
        // Top check icon (second check)
        if (isSeen)
          const Icon(
            Icons.check,
            color: Colors.blue,
            size: 14,
          ),
      ],
    );
  }
}
