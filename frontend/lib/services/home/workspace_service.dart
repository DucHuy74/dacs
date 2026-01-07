import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/home/workspace_model.dart';
import '../auth/auth_service.dart';

class WorkspaceService {
  static const String baseUrl = 'http://localhost:8080/api/workspace';

  Future<WorkspaceResponse?> createWorkspace({
    required String name,
    required WorkspaceType type,
    required WorkspaceAccess access,
  }) async {
    try {
      final token = await AuthService.instance.getValidAccessToken();

      if (token == null) {
        print('Error: No valid access token found');
        return null;
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'x-api-key': dotenv.env['API_KEY'] ?? '',
        },
        body: jsonEncode(<String, String>{
          'name': name,
          'type': type.name,
          'access': access.name,
        }),
      );

      if (response.statusCode == 200) {
        return WorkspaceResponse.fromJson(jsonDecode(response.body));
      } else {
        print('Server Error: ${response.statusCode} - ${response.body}');
        try {
          return WorkspaceResponse.fromJson(jsonDecode(response.body));
        } catch (_) {
          return null;
        }
      }
    } catch (e) {
      print('Connection Error: $e');
      return null;
    }
  }
}
