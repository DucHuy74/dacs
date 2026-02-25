class UserStoryModel {
  final String id;
  final String storyText;
  final String status;

  UserStoryModel({
    required this.id,
    required this.storyText,
    required this.status,
  });

  factory UserStoryModel.fromJson(Map<String, dynamic> json) {
    return UserStoryModel(
      id: json['id'] ?? '',
      storyText: json['storyText'] ?? '',
      status: json['status'] ?? 'ToDo',
    );
  }
}