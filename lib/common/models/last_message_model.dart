class LastMessageModel {
  final String username;
  final String? profileImageUrl;
  final String contactId;
  final DateTime timeSent;
  final String lastMessage;
  final String email;

  LastMessageModel({
    required this.username,
    this.profileImageUrl,
    required this.contactId,
    required this.timeSent,
    required this.lastMessage,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'profileImageUrl': profileImageUrl,
      'contactId': contactId,
      'timeSent': timeSent.millisecondsSinceEpoch,
      'lastMessage': lastMessage,
      'email': email,
    };
  }

  factory LastMessageModel.fromMap(Map<String, dynamic> map) {
    return LastMessageModel(
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      contactId: map['contactId'] ?? '',
      timeSent: DateTime.fromMillisecondsSinceEpoch(map['timeSent']),
      lastMessage: map['lastMessage'] ?? '',
    );
  }

  LastMessageModel copyWith({String? contactId}) {
    return LastMessageModel(
      username: username,
      profileImageUrl: profileImageUrl,
      contactId: contactId ?? this.contactId,
      timeSent: timeSent,
      lastMessage: lastMessage,
      email: email,
    );
  }
}
