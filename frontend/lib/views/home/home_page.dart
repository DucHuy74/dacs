import 'package:flutter/material.dart';
import 'package:frontend/auth/auth_gate.dart';
import '../../services/auth/auth_service.dart';
import 'space_templates.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0052CC),
        fontFamily: 'Segoe UI',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedMenu = 'For you';
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(isMobile),
      drawer: isMobile ? _buildDrawer() : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: const Color(0xFF0052CC),
      elevation: 0,
      leading: isMobile
          ? null
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Color(0xFF0052CC),
                  size: 20,
                ),
              ),
            ),
      title: Row(
        children: [
          if (!isMobile)
            const Text(
              'TaskFlow',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          if (!isMobile) const SizedBox(width: 24),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0747A6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            _showCreateDialog();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create', style: TextStyle(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0052CC),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () {},
        ),
        const SizedBox(width: 8),

        // --- LOGOUT MENU ---
        PopupMenuButton<int>(
          offset: const Offset(0, 48),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6554C0),
              child: const Text(
                'U',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          onSelected: (value) async {
            if (value == 1) {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm logout'),
                  content: const Text('Do you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await AuthService.instance.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const AuthGate(child: HomePage()),
                    ),
                    (route) => false,
                  );
                }
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<int>(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.logout, color: Color(0xFF172B4D)),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0052CC)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'TaskFlow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Project Management',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _buildMenuItem('For you', Icons.person_outline, false),
          _buildMenuItem('Recent', Icons.access_time, false),
          _buildMenuItem('Starred', Icons.star_border, false),
          _buildMenuItem('Apps', Icons.apps, false),
          _buildMenuItem('Plans', Icons.calendar_today_outlined, false),
          const Divider(),
          _buildMenuItem('Spaces', Icons.dashboard_outlined, false),
          _buildMenuItem('Filters', Icons.filter_list, false),
          _buildMenuItem('Dashboards', Icons.dashboard, false),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildMenuItem('For you', Icons.person_outline, true),
          _buildMenuItem('Recent', Icons.access_time, true),
          _buildMenuItem('Starred', Icons.star_border, true),
          _buildMenuItem('Apps', Icons.apps, true),
          _buildMenuItem('Plans', Icons.calendar_today_outlined, true),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spaces',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5E6C84),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _showCreateDialog();
                  },
                ),
              ],
            ),
          ),
          _buildMenuItem(
            'More spaces',
            Icons.chevron_right,
            true,
            indent: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(height: 1),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Recommended',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5E6C84),
              ),
            ),
          ),
          _buildMenuItem(
            'Create a roadmap',
            Icons.timeline,
            true,
            badge: 'TRY',
            indent: true,
          ),
          _buildMenuItem('Filters', Icons.filter_list, true, indent: true),
          _buildMenuItem('Dashboards', Icons.dashboard, true, indent: true),
          _buildMenuItem(
            'Operations',
            Icons.build_outlined,
            true,
            indent: true,
          ),
          _buildMenuItem('Customers', Icons.people_outline, true, indent: true),
          _buildMenuItem(
            'Customer experiences',
            Icons.headset_mic_outlined,
            true,
            indent: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(height: 1),
          ),
          _buildMenuItem(
            'Assets',
            Icons.extension_outlined,
            true,
            external: true,
            indent: true,
          ),
          _buildMenuItem(
            'Teams',
            Icons.groups_outlined,
            true,
            external: true,
            indent: true,
          ),
          _buildMenuItem(
            'Give feedback on the new...',
            Icons.feedback_outlined,
            true,
            indent: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData? icon,
    bool showText, {
    bool indent = false,
    String? badge,
    bool external = false,
  }) {
    final isSelected = _selectedMenu == title;
    return Container(
      margin: EdgeInsets.only(left: indent ? 24 : 0),
      child: ListTile(
        dense: true,
        leading: icon != null
            ? Icon(
                icon,
                size: 20,
                color: isSelected
                    ? const Color(0xFF0052CC)
                    : const Color(0xFF5E6C84),
              )
            : null,
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? const Color(0xFF0052CC)
                      : const Color(0xFF172B4D),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052CC),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (external)
              const Icon(Icons.open_in_new, size: 14, color: Color(0xFF5E6C84)),
          ],
        ),
        trailing: title == 'Recent' || title == 'Starred'
            ? const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF5E6C84),
              )
            : null,
        selected: isSelected,
        selectedTileColor: const Color(0xFFDEEBFF),
        onTap: () {
          setState(() => _selectedMenu = title);
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC400),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Color(0xFF172B4D),
                ),
                Positioned(
                  right: 15,
                  top: 20,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0052CC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vpn_key,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Space not found',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172B4D),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You tried to access a space that doesn\'t exist, or that you don\'t have permission to access. Speak to your Jira admin or space admin to get access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF5E6C84),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _showCreateDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Create your first scrum board',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Go back to home',
                style: TextStyle(
                  color: Color(0xFF0052CC),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SpaceTemplatesPage()),
    );
  }
}
