import 'package:flutter/material.dart';
import '../../services/backlog/create_userstory_service.dart';
import '../../models/backlog/task_status.dart';

class CreateUserStoryViewModel extends ChangeNotifier {
  final CreateUserStoryService _service = CreateUserStoryService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> createStory(String workspaceId, String text) async {
    if (text.trim().isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    final success = await _service.createUserStory(
      workspaceId: workspaceId,
      storyText: text,
      status: SprintStatus.ToDo, 
    );

    _isLoading = false;
    notifyListeners();
    
    return success;
  }
}