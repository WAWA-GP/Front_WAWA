// lib/models/user_profile.dart (새 파일)

class UserProfile {
  final String id;
  final String email;
  final Map<String, dynamic> userMetadata;

  UserProfile({
    required this.id,
    required this.email,
    required this.userMetadata,
  });

  // 서버 응답(JSON)에서 UserProfile 객체로 변환하는 팩토리 생성자
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['user_id'] ?? 'Unknown ID',
      email: json['email'] ?? 'No email provided',
      userMetadata: Map<String, dynamic>.from(json['user_metadata'] ?? {}),
    );
  }
}