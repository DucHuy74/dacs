import 'package:flutter/material.dart';
import '../../models/home/workspace_model.dart';

class WorkspaceHeader extends StatelessWidget {
  final WorkspaceModel workspace;
  final String activeTab;
  final ValueChanged<String> onTabSelected;

  const WorkspaceHeader({
    Key? key,
    required this.workspace,
    required this.activeTab,
    required this.onTabSelected,
  }) : super(key: key);

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(),
          const SizedBox(height: 20),
          _buildTabs(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _getAvatarColor(workspace.name),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            workspace.name.isNotEmpty ? workspace.name[0].toUpperCase() : "",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          workspace.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF172B4D)),
        ),
        const SizedBox(width: 12),
        IconButton(icon: const Icon(Icons.people_outline, size: 20), onPressed: () {}),
        IconButton(icon: const Icon(Icons.star_border, size: 20), onPressed: () {}),
        const Spacer(),
        IconButton(icon: const Icon(Icons.share_outlined, size: 20), onPressed: () {}),
        IconButton(icon: const Icon(Icons.flash_on_outlined, size: 20), onPressed: () {}),
        IconButton(icon: const Icon(Icons.fullscreen, size: 20), onPressed: () {}),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = {
      'Summary': Icons.summarize_outlined,
      'Timeline': Icons.timeline_outlined,
      'Backlog': Icons.view_list,
      'Graph': Icons.hub_outlined,
      'Board': Icons.dashboard_outlined,
      'Calendar': Icons.calendar_today_outlined,
      'List': Icons.list_alt,
      'Forms': Icons.assignment_outlined,
      'Development': Icons.code,
      'Code': Icons.integration_instructions,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...tabs.entries.map((e) => _buildTabItem(e.key, e.value)),
          TextButton(
            onPressed: () {},
            child: const Text('More', style: TextStyle(color: Color(0xFF5E6C84))),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, IconData icon) {
    bool isActive = activeTab == title;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onTabSelected(title),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFDEEBFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? const Color(0xFF0052CC) : const Color(0xFF42526E),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? const Color(0xFF0052CC) : const Color(0xFF42526E),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}