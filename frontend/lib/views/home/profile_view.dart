// profile_view.dart

import 'package:flutter/material.dart';
import '../../models/home/user_profile_model.dart';
import '../../services/home/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileService().fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1E1F22);
    const cardColor = Color(0xFF2B2D31);
    const textColor = Colors.white;
    const subTextColor = Color(0xFFA0A0A0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0052CC)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          } else if (snapshot.hasData) {
            final profile = snapshot.data!;
            final fullName = '${profile.lastName} ${profile.firstName}';

            final displayUsername = '@${profile.username}';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- AVATAR & TÊN ---
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0052CC),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: cardColor,
                            child: Text(
                              profile.firstName.isNotEmpty
                                  ? profile.firstName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0C070),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: backgroundColor,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    fullName,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayUsername,
                    style: const TextStyle(
                      color: Color(0xFFF0C070),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- THÔNG TIN CHI TIẾT (DẠNG CARD) ---
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Full Name',
                          value: fullName,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.alternate_email,
                          label: 'Username',
                          value: profile.username,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: profile
                              .email, // Nhớ thêm trường email vào user_profile_model.dart
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date of Birth',
                          value: profile
                              .dob, // Nhớ thêm trường dob vào user_profile_model.dart
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ), // Giữ lại một chút khoảng trống dưới cùng để khi cuộn không bị sát viền
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Colors.white12,
      height: 1,
      indent: 56,
      endIndent: 16,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color subTextColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
      title: Text(label, style: TextStyle(color: subTextColor, fontSize: 13)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
