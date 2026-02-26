import 'package:flutter/material.dart';
import '../../models/backlog/sprint_model.dart';
import '../../models/backlog/user_story_model.dart';
import '../../services/backlog/sprint_service.dart';
import 'sprint_graph_screen.dart'; 

class SprintSection extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onCreateStory;
  final List<SprintModel> sprints;
  final Function(String sprintId, String storyId) onMoveStoryToSprint;

  const SprintSection({
    Key? key,
    required this.controller,
    required this.onCreateStory,
    required this.sprints,
    required this.onMoveStoryToSprint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (sprints.isEmpty) {
      return _buildEmptySprintState();
    }

    return Column(
      children: sprints
          .map(
            (sprint) => SprintContainer(
              sprint: sprint,
              onMoveStoryToSprint: onMoveStoryToSprint,
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptySprintState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFDEEBFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 32,
                color: Color(0xFF0052CC),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Plan your sprint',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172B4D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Drag work items from the Backlog section or create new ones.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF5E6C84)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SPRINT CONTAINER ---
class SprintContainer extends StatefulWidget {
  final SprintModel sprint;
  final Function(String sprintId, String storyId) onMoveStoryToSprint;

  const SprintContainer({
    Key? key,
    required this.sprint,
    required this.onMoveStoryToSprint,
  }) : super(key: key);

  @override
  State<SprintContainer> createState() => _SprintContainerState();
}

class _SprintContainerState extends State<SprintContainer> {
  final SprintService _sprintService = SprintService();
  late Future<List<UserStoryModel>> _storiesFuture;
  bool _isStarting = false; // [MỚI] Biến để hiển thị loading khi bấm nút start

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void didUpdateWidget(covariant SprintContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sprint != widget.sprint) {
      _loadStories();
    }
  }

  void _loadStories() {
    setState(() {
      _storiesFuture = _sprintService.getStoriesInSprint(widget.sprint.id);
    });
  }

  // --- [MỚI] Hàm xử lý khi bấm nút Start Sprint ---
  void _handleStartSprint() async {
    setState(() => _isStarting = true);

    // 1. Gọi API Start Sprint
    bool success = await _sprintService.startSprint(widget.sprint.id);

    setState(() => _isStarting = false);

    if (mounted) {
      if (success) {
        // 2. Nếu thành công -> Chuyển sang màn hình Graph
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SprintGraphScreen(
              sprintId: widget.sprint.id,
              sprintName: widget.sprint.name,
            ),
          ),
        );
      } else {
        // Nếu thất bại -> Báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start sprint. Check if another sprint is active.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${date.day} ${months[date.month - 1]}";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateRange = "";
    if (widget.sprint.startDate != null && widget.sprint.endDate != null) {
      dateRange = "${_formatDate(widget.sprint.startDate)} - ${_formatDate(widget.sprint.endDate)}";
    }

    return DragTarget<String>(
      onWillAccept: (data) => data != null,
      onAccept: (storyId) {
        widget.onMoveStoryToSprint(widget.sprint.id, storyId);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: isHovering ? const Color(0xFFE3FCEF) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: isHovering ? Border.all(color: Colors.green, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(dateRange),
              FutureBuilder<List<UserStoryModel>>(
                future: _storiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  final stories = snapshot.data ?? [];
                  if (stories.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: const Text(
                        "Plan a sprint by dragging work items into it.",
                        style: TextStyle(color: Color(0xFFC1C7D0), fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stories.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEBECF0)),
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      return Draggable<String>(
                        data: story.id,
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: 300,
                            padding: const EdgeInsets.all(12),
                            color: Colors.white,
                            child: Text(story.storyText),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _buildSprintTaskItem(story),
                        ),
                        child: _buildSprintTaskItem(story),
                      );
                    },
                  );
                },
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.transparent, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSprintTaskItem(UserStoryModel story) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.check_box_outline_blank, size: 18, color: Color(0xFFDFE1E6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(story.storyText, style: const TextStyle(fontSize: 14, color: Color(0xFF172B4D))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFDFE1E6), borderRadius: BorderRadius.circular(3)),
            child: Text(
              story.status.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF42526E)),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 10,
            backgroundColor: Color(0xFF0052CC),
            child: Text("Q", style: TextStyle(fontSize: 10, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String dateRange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFEBECF0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF42526E)),
          const SizedBox(width: 8),
          Text(
            widget.sprint.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(width: 12),
          if (dateRange.isNotEmpty)
            Text(dateRange, style: const TextStyle(fontSize: 13, color: Color(0xFF5E6C84))),
          const Spacer(),
          
          // --- [MỚI] Nút Start Sprint đã tích hợp logic ---
          ElevatedButton(
            onPressed: _isStarting ? null : _handleStartSprint, // Disable nút khi đang loading
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF4F5F7),
              foregroundColor: const Color(0xFF42526E),
              elevation: 0,
              side: const BorderSide(color: Color(0xFFDFE1E6)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 32),
            ),
            child: _isStarting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Text('Start sprint', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 20, color: Color(0xFF42526E)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}