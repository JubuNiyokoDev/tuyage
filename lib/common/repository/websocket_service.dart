import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  final WebSocketChannel channel;

  WebSocketService(String url) : channel = IOWebSocketChannel.connect(url);

  void sendMessage(String userId) {
    final message = jsonEncode({'userId': userId});
    channel.sink.add(message);
  }

  Stream<dynamic> get messages => channel.stream;

  void dispose() {
    channel.sink.close();
  }
}
