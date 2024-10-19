class Status {
  final String uid;
  final String username;
  final String phoneNumber;
  final String profilePic;
  final String statusId;
  final DateTime createdAt;
  final List<String> photoUrl;
  final List<String> whoCanSee;

  Status({
    required this.uid,
    required this.username,
    required this.phoneNumber,
    required this.profilePic,
    required this.statusId,
    required this.createdAt,
    required this.photoUrl,
    required this.whoCanSee,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'statusId': statusId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'photoUrl': photoUrl,
      'whoCanSee': whoCanSee,
    };
  }

  factory Status.fromMap(Map<String, dynamic> map) {
    return Status(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePic: map['profilePic'] ?? '',
      statusId: map['statusId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      photoUrl: List<String>.from(map['photoUrl']),
      whoCanSee: List<String>.from(map['whoCanSee']),
    );
  }
}
