import 'dart:io';
import 'dart:typed_data';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:enough_giphy_flutter/enough_giphy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tuyage/common/enum/message_type.dart';
import 'package:tuyage/common/extension/custom_theme_extension.dart';
import 'package:tuyage/common/helper/show_alert_dialog.dart';
import 'package:tuyage/common/providers/message_reply_provider.dart';
import 'package:tuyage/common/utils/coloors.dart';
import 'package:tuyage/common/widgets/custom_icon_button.dart';
import 'package:tuyage/feature/auth/pages/image_picker_page.dart';
import 'package:tuyage/feature/chat/controller/chat_controller.dart';
import 'package:tuyage/feature/chat/widgets/message_reply_preview.dart';

class ChatTextField extends ConsumerStatefulWidget {
  const ChatTextField({
    super.key,
    required this.receiverId,
    required this.scrollController,
    required this.isGroupChat,
  });

  final String receiverId;
  final bool isGroupChat;
  final ScrollController scrollController;

  @override
  ConsumerState<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends ConsumerState<ChatTextField> {
  late TextEditingController messageController;
  FlutterSoundRecorder? _soundRecorder;
  bool isMessageIconEnabled = false;
  bool isShowEmojiContainer = false;
  double cardHeight = 0;
  File? imageCamera;
  Uint8List? imageGallery;
  FocusNode focusNode = FocusNode();
  bool isRecorderInit = false;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    _soundRecorder = FlutterSoundRecorder();
    openAudio();
  }

  void openAudio() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Permission ya Micro ntiwayemeye!');
    }
    await _soundRecorder!.openRecorder();
    isRecorderInit = true;
  }

  void pickImageFromCamera(BuildContext context) async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image != null) {
        imageCamera = File(image.path);
        sendFileMessage(imageCamera, MessageType.image);
        setState(() => cardHeight = 0);
      }
    } catch (e) {
      showAlertDialog(context: context, message: e.toString());
    }
  }

  void selectVideo() async {
    File? video = await pickVideoFromGallery(context);
    if (video != null) {
      sendFileMessage(video, MessageType.video);
    }
  }

  void selectGIF() async {
    final gif = await pickGIF(context);
    if (gif != null) {
      ref.read(chatControllerProvider).SendGIFMessage(
            context,
            gif.url,
            widget.receiverId,
            widget.isGroupChat,
          );
    }
  }

  void sendImageMessageFromGallery() async {
    final image = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ImagePickerPage(),
        ));

    if (image != null) {
      sendFileMessage(image, MessageType.image);
      setState(() => cardHeight = 0);
    } else {
      print("$image");
    }
  }

  Future<File?> pickVideoFromGallery(BuildContext conetxt) async {
    File? video;
    try {
      final pickedVideo =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedVideo != null) {
        video = File(pickedVideo.path);
      } else {
        print("$video");
      }
    } catch (e) {
      showAlertDialog(context: context, message: e.toString());
    }
    return video;
  }

  Future<GiphyGif?> pickGIF(BuildContext context) async {
    GiphyGif? gif;
    try {
      gif = await Giphy.getGif(
        context: context,
        apiKey: 'TNWl6v9PFM6WR7jOOS4jYpneA04B58b1',
      );
    } catch (e) {
      showAlertDialog(context: context, message: e.toString());
    }
    return gif;
  }

  void sendFileMessage(var file, MessageType messageType) async {
    ref.read(chatControllerProvider).sendFileMessage(
          context: context,
          file: file,
          messageType: messageType,
          receiverId: widget.receiverId,
          isGroupChat: widget.isGroupChat,
        );

    await Future.delayed(const Duration(milliseconds: 500));
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void sendTextMessage() async {
    if (isMessageIconEnabled) {
      ref.read(chatControllerProvider).sendTextMessage(
            context: context,
            textMessage: messageController.text.trim(),
            receiverId: widget.receiverId,
            isGroupChat: widget.isGroupChat,
          );

      messageController.clear();
    } else {
      var tempDir = await getTemporaryDirectory();
      var path = '${tempDir.path}/flutter_sound.aac';
      if (!isRecorderInit) {
        return;
      }
      if (isRecording) {
        await _soundRecorder!.stopRecorder();
        sendFileMessage(File(path), MessageType.audio);
      } else {
        await _soundRecorder!.startRecorder(
          toFile: path,
        );
      }

      setState(() {
        isRecording = !isRecording;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  iconWithText({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required Color background,
  }) {
    return Column(
      children: [
        CustomIconButton(
          onPressed: onPressed,
          icon: icon,
          background: background,
          minWidth: 50,
          iconColor: Colors.white,
          border: Border.all(
            color: context.theme.greyColor!.withOpacity(.2),
            width: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(
            color: context.theme.greyColor,
          ),
        )
      ],
    );
  }

  void hideEmojiContainer() {
    setState(() {
      isShowEmojiContainer = false;
    });
  }

  void showEmojiContainer() {
    setState(() {
      isShowEmojiContainer = true;
    });
  }

  void showKeyboard() => focusNode.requestFocus();
  void hideKeyboard() => focusNode.unfocus();
  void toggleEmojiKeyboardContainer() {
    if (isShowEmojiContainer) {
      showKeyboard();
      hideEmojiContainer();
    } else {
      hideKeyboard();
      showEmojiContainer();
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
    _soundRecorder!.closeRecorder();
    isRecorderInit = false;
  }

  @override
  Widget build(BuildContext context) {
    final messageReply = ref.watch(messageReplyProvider);
    final isShowMessageReply = messageReply != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isShowMessageReply ? const MessageReplyPreview() : const SizedBox(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: cardHeight,
          width: double.maxFinite,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: context.theme.receiverChatCardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      iconWithText(
                        onPressed: () {},
                        icon: Icons.file_open_rounded,
                        text: 'File',
                        background: const Color(0xFF7F66FE),
                      ),
                      iconWithText(
                        onPressed: () => pickImageFromCamera(context),
                        icon: Icons.camera_outlined,
                        text: 'Camera',
                        background: const Color(0xFFFE2E74),
                      ),
                      iconWithText(
                        onPressed: selectVideo,
                        icon: Icons.video_collection,
                        text: 'Video',
                        background: const Color(0xFF7F66FE),
                      ),
                      iconWithText(
                        onPressed: sendImageMessageFromGallery,
                        icon: Icons.photo_outlined,
                        text: 'Gallery',
                        background: const Color(0xFFC861F9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      iconWithText(
                        onPressed: () {},
                        icon: Icons.headphones,
                        text: 'Audio',
                        background: const Color(0xFFF96533),
                      ),
                      iconWithText(
                        onPressed: () {},
                        icon: Icons.location_on,
                        text: 'Loaction',
                        background: const Color(0xFF1FA855),
                      ),
                      iconWithText(
                        onPressed: () {},
                        icon: Icons.person,
                        text: 'Contact',
                        background: const Color(0xFF009DE1),
                      ),
                      iconWithText(
                        onPressed: () {},
                        icon: Icons.poll_outlined,
                        text: 'Poll',
                        background: Coloors.greenLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  focusNode: focusNode,
                  controller: messageController,
                  maxLines: 4,
                  minLines: 1,
                  onChanged: (value) {
                    value.isEmpty
                        ? setState(() {
                            isMessageIconEnabled = false;
                          })
                        : setState(() {
                            isMessageIconEnabled = true;
                          });
                  },
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: context.theme.greyColor),
                    filled: true,
                    fillColor: context.theme.chatTextFieldBg,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        style: BorderStyle.none,
                        width: 0,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    prefixIcon: Material(
                      color: Colors.transparent,
                      child: CustomIconButton(
                        onPressed: toggleEmojiKeyboardContainer,
                        icon: Icons.emoji_emotions_outlined,
                        iconColor: Theme.of(context).listTileTheme.iconColor,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconButton(
                          onPressed: selectGIF,
                          icon: Icons.gif,
                          iconColor: Theme.of(context).listTileTheme.iconColor,
                        ),
                        RotatedBox(
                          quarterTurns: 45,
                          child: CustomIconButton(
                            onPressed: () => setState(
                              () => cardHeight == 0
                                  ? cardHeight = 300
                                  : cardHeight = 0,
                            ),
                            icon: cardHeight == 0
                                ? Icons.attach_file
                                : Icons.close,
                            iconColor:
                                Theme.of(context).listTileTheme.iconColor,
                          ),
                        ),
                        CustomIconButton(
                          onPressed: () => pickImageFromCamera(context),
                          icon: Icons.camera_alt_outlined,
                          iconColor: Theme.of(context).listTileTheme.iconColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              CustomIconButton(
                onPressed: sendTextMessage,
                icon: isMessageIconEnabled
                    ? Icons.send_outlined
                    : isRecording
                        ? Icons.close
                        : Icons.mic_none_outlined,
                background: Coloors.greenDark,
                iconColor: Colors.white,
              ),
            ],
          ),
        ),
        isShowEmojiContainer
            ? SizedBox(
                height: 310,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    setState(() {
                      messageController.text =
                          messageController.text + emoji.emoji;
                    });
                    if (!isMessageIconEnabled) {
                      setState(() {
                        isMessageIconEnabled = true;
                      });
                    }
                  },
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
