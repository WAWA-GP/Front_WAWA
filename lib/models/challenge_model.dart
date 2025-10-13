// models/challenge_model.dart

class GroupChallenge {
  final int id;
  final int groupId;
  final String creatorId; // 생성자 ID
  final String creatorName; // 생성자 이름
  final String title;
  final String description;
  final String challengeType;
  final int targetValue;
  final int userCurrentValue; // 개인의 현재 달성치
  final bool isCompleted;
  final DateTime endDate;
  final bool isActive;

  GroupChallenge({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.targetValue,
    required this.userCurrentValue,
    required this.isCompleted,
    required this.endDate,
    required this.isActive,
  });

  factory GroupChallenge.fromJson(Map<String, dynamic> json) {
    return GroupChallenge(
      id: json['id'],
      groupId: json['group_id'],
      creatorId: json['creator_id'],
      creatorName: json['creator_name'],
      title: json['title'],
      description: json['description'] ?? '',
      challengeType: json['challenge_type'],
      targetValue: json['target_value'],
      userCurrentValue: json['user_current_value'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'] ?? true,
    );
  }
}