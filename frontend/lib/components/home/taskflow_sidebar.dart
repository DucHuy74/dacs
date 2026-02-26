import 'package:flutter/material.dart';
import '../../models/home/workspace_model.dart';

class TaskFlowSidebar extends StatelessWidget {
  final String selectedMenu;
  final Function(String) onMenuSelected;
  final VoidCallback onCreate;
  final List<WorkspaceModel> workspaces;

  const TaskFlowSidebar({
    Key? key,
    required this.selectedMenu,
    required this.onMenuSelected,
    required this.onCreate,
    this.workspaces = const [],
  }) : super(key: key);

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "";
    return name.trim()[0].toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF0052CC),
      const Color(0xFFDE350B),
      const Color(0xFF008DA6),
      const Color(0xFF403294),
      const Color(0xFFFF991F),
    ];
    return colors[name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: onCreate,
                ),
              ],
            ),
          ),

          if (workspaces.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                "No workspaces found",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...workspaces.map((ws) => _buildWorkspaceItem(ws)).toList(),

          // --- MENU DƯỚI ---
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

  Widget _buildWorkspaceItem(WorkspaceModel ws) {
    final isSelected = selectedMenu == ws.name; // So sánh tên để highlight

    return Container(
      margin: const EdgeInsets.only(left: 12),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 0, right: 12),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _getAvatarColor(ws.name),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            _getInitials(ws.name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          ws.name,
          style: TextStyle(
            fontSize: 14,
            color: isSelected
                ? const Color(0xFF0052CC)
                : const Color(0xFF172B4D),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFFDEEBFF),

        onTap: () => onMenuSelected(ws.name),
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
    final isSelected = selectedMenu == title;
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
        onTap: () => onMenuSelected(title),
      ),
    );
  }
}
