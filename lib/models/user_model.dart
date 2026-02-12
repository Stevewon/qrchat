class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? qrCode;
  final DateTime createdAt;
  final DateTime lastSeen;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.qrCode,
    required this.createdAt,
    required this.lastSeen,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      qrCode: map['qrCode'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastSeen: DateTime.parse(map['lastSeen'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'qrCode': qrCode,
      'createdAt': createdAt.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
    };
  }
}
