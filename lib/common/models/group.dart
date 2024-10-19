import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String senderId;
  final String name;
  final String groupId;
  final String lastMessage;
  final String? profilePic;
  final String groupPic;
  final List<String> membersUid;
  final DateTime timeSent;

  Group({
    required this.groupId,
    required this.groupPic,
    required this.lastMessage,
    required this.membersUid,
    required this.name,
    this.profilePic,
    required this.senderId,
    required this.timeSent,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'name': name,
      'groupId': groupId,
      'lastMessage': lastMessage,
      'profilePic': profilePic,
      'groupPic': groupPic,
      'membersUid': membersUid,
      'timeSent': timeSent,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      groupId: map['groupId'] ?? '',
      timeSent: (map['timeSent'] as Timestamp).toDate(), // Conversion correcte
      groupPic: map['groupPic'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      membersUid: List<String>.from(map['membersUid']),
      name: map['name'] ?? '',
      senderId: map['senderId'] ?? '',
      profilePic: map['profilePic'], // Gérer les valeurs nulles correctement
    );
  }
}
