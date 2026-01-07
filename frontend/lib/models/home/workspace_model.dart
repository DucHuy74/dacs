// lib/models/home/workspace_model.dart

// 1. Định nghĩa lại Enum (hoặc import từ file khác nếu bạn đã tách riêng)
enum WorkspaceType { TEAM_MANAGED, COMPANY_MANAGED }
enum WorkspaceAccess { OPEN, PRIVATE, LIMITED }

// 2. Class Backlog (Đối tượng con bên trong result)
class Backlog {
  final String id;
  final String name;

  Backlog({required this.id, required this.name});

  factory Backlog.fromJson(Map<String, dynamic> json) {
    return Backlog(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

// 3. Class WorkspaceData (Đối tượng "result")
class WorkspaceData {
  final String id;
  final String name;
  final WorkspaceType type;
  final WorkspaceAccess access;
  final Backlog? backlog;
  final String createdAt;
  final String updatedAt;

  WorkspaceData({
    required this.id,
    required this.name,
    required this.type,
    required this.access,
    this.backlog,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkspaceData.fromJson(Map<String, dynamic> json) {
    return WorkspaceData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      // Chuyển String từ API sang Enum
      type: WorkspaceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WorkspaceType.TEAM_MANAGED,
      ),
      access: WorkspaceAccess.values.firstWhere(
        (e) => e.name == json['access'],
        orElse: () => WorkspaceAccess.OPEN,
      ),
      backlog: json['backlog'] != null ? Backlog.fromJson(json['backlog']) : null,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

// 4. Class WorkspaceResponse (Đối tượng gốc trả về từ API)
class WorkspaceResponse {
  final int code;
  final String message;
  final WorkspaceData? result;

  WorkspaceResponse({
    required this.code,
    required this.message,
    this.result,
  });

  factory WorkspaceResponse.fromJson(Map<String, dynamic> json) {
    return WorkspaceResponse(
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      result: json['result'] != null ? WorkspaceData.fromJson(json['result']) : null,
    );
  }
}