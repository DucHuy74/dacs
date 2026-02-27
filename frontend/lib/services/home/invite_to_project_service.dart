import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/auth_service.dart';

class InvitationService {
  static const String _baseUrl = 'http://localhost:8080/api'; 

  // [MỚI] Thêm tham số role
  Future<bool> sendInvites(String workspaceId, List<String> emails, String role) async {
    final url = Uri.parse('$_baseUrl/workspace/$workspaceId/invitations');
    final token = await AuthService.instance.getValidAccessToken();

    try {
      List<Future<http.Response>> requests = emails.map((email) {
        return http.post(
          url,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
            'x-api-key': dotenv.env['API_KEY'] ?? '',
          },
          body: jsonEncode({
            "email": email,
            "role": role 
          }),
        );
      }).toList();

      final responses = await Future.wait(requests);
      bool allSuccess = responses.every((res) => res.statusCode >= 200 && res.statusCode < 300);
      return allSuccess;
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}