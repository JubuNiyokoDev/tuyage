import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuyage/common/models/call.dart';
import 'package:tuyage/config/agora_config.dart';
import 'package:tuyage/feature/call/controller/call_controller.dart';
import 'package:tuyage/feature/call/respository/call_repository.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String channelId;
  final Call call;
  final bool isGroupChat;

  const CallScreen({
    Key? key,
    required this.call,
    required this.channelId,
    required this.isGroupChat,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CallScreen();
}

class _CallScreen extends ConsumerState<CallScreen> {
  AgoraClient? client;
  String baseUrl = 'https://flutter-twitch-server-4xp8.onrender.com/';

  @override
  void initState() {
    super.initState();
    client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: AgoraConfig.apId,
        channelName: widget.channelId,
        tokenUrl: baseUrl,
      ),
    );
    initAgora();
  }

  void initAgora() async {
    try {
      await client!.initialize();
      print("Agora client initialized successfully.");
    } catch (e) {
      print("Error initializing Agora client: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: client == null
          ? const CircularProgressIndicator()
          : SafeArea(
              child: Stack(
                children: [
                  AgoraVideoViewer(client: client!),
                  AgoraVideoButtons(
                    client: client!,
                    disconnectButtonChild: IconButton(
                      onPressed: () async {
                        await client!.engine.leaveChannel();
                        widget.isGroupChat
                            ? ref.read(callControllerProvider).endCall(
                                  widget.call.callerId,
                                  widget.call.receiverId,
                                  context,
                                )
                            : ref.read(callRepositoryProvider).endGroupCall(
                                  widget.call.callerId,
                                  widget.call.receiverId,
                                  context,
                                );
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.call_end,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
