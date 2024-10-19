import 'package:flutter/material.dart';
import 'package:tuyage/common/routes/routes.dart';

class CallHomePage extends StatelessWidget {
  const CallHomePage({super.key});

  navigateToCallPage(context) {
    Navigator.pushNamed(context, Routes.contact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text("Call Home Page"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToCallPage(context),
        child: const Icon(
          Icons.call,
        ),
      ),
    );
  }
}
