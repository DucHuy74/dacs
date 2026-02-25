import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/auth_service.dart';
import '../../models/backlog/task_status.dart';

class CreateUserStoryService {
  static const String _baseUrl = 'http://localhost:8080/api'; 

  Future<bool> createUserStory({
    required String workspaceId,
    required String storyText,
    SprintStatus status = SprintStatus.ToDo,
  }) async {
    final url = Uri.parse('$_baseUrl/user-stories/workspace/$workspaceId');

    try {
      final token = await AuthService.instance.getValidAccessToken();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',        
          'x-api-key': dotenv.env['API_KEY'] ?? '',  
        },
        body: jsonEncode({
          "workspaceId": workspaceId,
          "storyText": storyText,
          "status": status.name, 
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['code'] == 1000) {
          return true; 
        }
      }

      print('Create User Story Error: ${response.statusCode} - ${response.body}');
      return false;

    } catch (e) {
      print('Exception: $e');
      return false; 
    }
  }
}