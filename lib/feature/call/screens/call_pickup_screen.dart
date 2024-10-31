import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/models/call.dart';
import 'package:tuyage/common/widgets/custom_icon_button.dart';
import 'package:tuyage/feature/call/controller/call_controller.dart';
import 'package:tuyage/feature/call/screens/call_screen.dart';

class CallPickupScreen extends ConsumerWidget {
  final Widget scaffold;
  const CallPickupScreen({
    super.key,
    required this.scaffold,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot>(
      stream: ref.watch(callControllerProvider).callStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.data() != null) {
          Call call =
              Call.fromMap(snapshot.data!.data() as Map<String, dynamic>);
          if (!call.hasDialled) {
            return Scaffold(
              body: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Incomming Call',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 50),
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: call.callerPic ?? '',
                        placeholder: (context, url) => CircleAvatar(
                          radius: 60,
                          backgroundColor: context.theme.greyColor,
                          child: const CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          radius: 60,
                          backgroundColor: context.theme.greyColor,
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          radius: 60,
                          backgroundImage: imageProvider,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    Text(
                      call.callerName,
                      style: const TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconButton(
                          onPressed: () {},
                          icon: Icons.call_end,
                          iconColor: Colors.redAccent,
                        ),
                        const SizedBox(width: 50),
                        CustomIconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CallScreen(
                                  call: call,
                                  channelId: call.callId,
                                  isGroupChat: false,
                                ),
                              ),
                            );
                          },
                          icon: Icons.call,
                          iconColor: Colors.green,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }
        }
        return scaffold;
      },
    );
  }
}
