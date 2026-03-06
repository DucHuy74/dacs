// lib/components/home/sprint_graph_screen.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../models/backlog/user_story_model.dart';
import '../../services/backlog/sprint_service.dart';
import '../../services/backlog/userstory_service.dart';
import '../../models/backlog/task_status.dart';

// =============================================================================
// THEME CONFIGURATION
// =============================================================================
class GraphTheme {
  final Color bgColor;
  final Color subjectFill;
  final Color subjectBorder;
  final Color verbFill;
  final Color verbBorder;
  final Color objectFill;
  final Color objectBorder;
  final Color lineColor;
  final Color highlightLine;
  final Color textPrimary;
  final Color textSecondary;
  final Color doneColor;
  final Color inProgressColor;
  final Color panelBg;
  final Color panelBorder;
  final Color tooltipShadow;
  final Color lassoColor;
  final Color selectionBorder;

  GraphTheme({
    required this.bgColor,
    required this.subjectFill,
    required this.subjectBorder,
    required this.verbFill,
    required this.verbBorder,
    required this.objectFill,
    required this.objectBorder,
    required this.lineColor,
    required this.highlightLine,
    required this.textPrimary,
    required this.textSecondary,
    required this.doneColor,
    required this.inProgressColor,
    required this.panelBg,
    required this.panelBorder,
    required this.tooltipShadow,
    required this.lassoColor,
    required this.selectionBorder,
  });

  factory GraphTheme.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? GraphTheme.dark() : GraphTheme.light();
  }

  factory GraphTheme.dark() => GraphTheme(
    bgColor: const Color(0xFF0D1117),
    subjectFill: const Color(0xFF161B22),
    subjectBorder: const Color(0xFF58A6FF),
    verbFill: const Color(0xFF1A1040),
    verbBorder: const Color(0xFF7C3AED),
    objectFill: const Color(0xFF0D1117),
    objectBorder: const Color(0xFF22D3EE),
    lineColor: const Color(0x556E7FBF),
    highlightLine: const Color(0xFF818CF8),
    textPrimary: const Color(0xFFE6EDF3),
    textSecondary: const Color(0xFF8B949E),
    doneColor: const Color(0xFF238636),
    inProgressColor: const Color(0xFFD29922),
    panelBg: const Color(0xFF161B22),
    panelBorder: const Color(0xFF30363D),
    tooltipShadow: Colors.black.withOpacity(0.5),
    lassoColor: Colors.white70,
    selectionBorder: Colors.white,
  );

  factory GraphTheme.light() => GraphTheme(
    bgColor: const Color(0xFFF4F5F7),
    subjectFill: Colors.white,
    subjectBorder: const Color(0xFF0052CC),
    verbFill: const Color(0xFFEAE6FF),
    verbBorder: const Color(0xFF5243AA),
    objectFill: Colors.white,
    objectBorder: const Color(0xFF00B8D9),
    lineColor: const Color(0xFFDFE1E6),
    highlightLine: const Color(0xFF0052CC),
    textPrimary: const Color(0xFF172B4D),
    textSecondary: const Color(0xFF5E6C84),
    doneColor: const Color(0xFF00875A),
    inProgressColor: const Color(0xFFFF991F),
    panelBg: Colors.white,
    panelBorder: const Color(0xFFDFE1E6),
    tooltipShadow: const Color(0xFF091E42).withOpacity(0.15),
    lassoColor: const Color(0xFF0052CC).withOpacity(0.7),
    selectionBorder: const Color(0xFF172B4D),
  );
}

// =============================================================================
// INTERNAL MODEL
// =============================================================================
class SprintSvoStory {
  final String id;
  final String rawText;
  final String subject;
  final String verb;
  final String object;
  final String status;

  SprintSvoStory({
    required this.id,
    required this.rawText,
    required this.subject,
    required this.verb,
    required this.object,
    required this.status,
  });
}

// =============================================================================
// MAIN SCREEN
// =============================================================================
class SprintGraphScreen extends StatefulWidget {
  final String sprintId;
  final String sprintName;

  const SprintGraphScreen({
    Key? key,
    required this.sprintId,
    required this.sprintName,
  }) : super(key: key);

  @override
  State<SprintGraphScreen> createState() => _SprintGraphScreenState();
}

enum NodeType { subject, verb, object }

class _SprintGraphScreenState extends State<SprintGraphScreen>
    with SingleTickerProviderStateMixin {
  final SprintService _sprintService = SprintService();
  final UserStoryService _userStoryService = UserStoryService();

  bool _isLoading = true;
  String? _errorMessage;

  List<SprintSvoStory> _stories = [];
  Map<String, Offset> nodePositions = {};
  Map<String, String> verbToTargetKey = {};

  Set<String> expandedSubjects = {};
  Set<String> zonedSubjects = {};
  bool _isZoningMode = false;
  String? _hoveredNodeKey;

  bool _isLassoMode = false;
  List<Offset> _drawnPoints = [];
  Set<String> _selectedNodeKeys = {};

  late AnimationController _spinController;

  GraphTheme get theme => GraphTheme.of(context);

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadSprintStories();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SprintGraphScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sprintId != widget.sprintId) {
      _loadSprintStories();
    }
  }

  Future<void> _loadSprintStories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<UserStoryModel> apiStories = await _sprintService
          .getStoriesInSprint(widget.sprintId);

      List<SprintSvoStory> parsedStories = apiStories.map((story) {
        final text = story.storyText.toLowerCase();
        String subject = "user";
        String verb = "action";
        String object = "target";

        final iWantToIdx = text.indexOf("i want to");
        if (iWantToIdx != -1) {
          final asAIdx = text.indexOf("as a");
          if (asAIdx != -1) {
            final commaIdx = text.indexOf(",", asAIdx);
            if (commaIdx != -1 && commaIdx < iWantToIdx) {
              subject = text.substring(asAIdx + 4, commaIdx).trim();
            }
          }
          final parts = text.substring(iWantToIdx + 9).trim().split(" ");
          if (parts.isNotEmpty) {
            verb = parts[0];
            if (parts.length > 1) {
              object = parts.sublist(1).join(" ").split("so that")[0].trim();
            }
          }
        }
        return SprintSvoStory(
          id: story.id,
          rawText: story.storyText,
          subject: subject,
          verb: verb,
          object: object,
          status: story.status,
        );
      }).toList();

      setState(() {
        _stories = parsedStories;
        expandedSubjects.addAll(_getUniqueSubjects(parsedStories));
        _calculateLayout(parsedStories);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi tải dữ liệu Sprint: $e";
        _isLoading = false;
      });
    }
  }

  List<String> _getUniqueSubjects(List<SprintSvoStory> stories) {
    return stories.map((s) => s.subject).toSet().toList();
  }

  bool _isObjectASubject(String objectName, List<SprintSvoStory> stories) {
    return _getUniqueSubjects(stories).contains(objectName);
  }

  String _makeObjectKey(String name, String status) => "obj_${name}_$status";

  void _calculateLayout(List<SprintSvoStory> stories) {
    nodePositions.clear();
    verbToTargetKey.clear();

    List<String> subjects = _getUniqueSubjects(stories);
    const double subjectX = 150;
    const double verbX = 420;
    const double objectX = 720;
    double currentSubjectY = 140;
    const double subjectSpacing = 160;
    const double verbSpacing = 80;

    for (var subName in subjects) {
      nodePositions["sub_$subName"] = Offset(subjectX, currentSubjectY);
      currentSubjectY += subjectSpacing;
    }

    double globalVerbY = 140;
    for (var subName in subjects) {
      if (!expandedSubjects.contains(subName)) continue;
      final filteredStories = stories
          .where((e) => e.subject == subName)
          .toList();
      for (var story in filteredStories) {
        String verbKey = "verb_${story.id}";
        nodePositions[verbKey] = Offset(verbX, globalVerbY);
        String targetKey = _isObjectASubject(story.object, stories)
            ? "sub_${story.object}"
            : _makeObjectKey(story.object, story.status);
        verbToTargetKey[verbKey] = targetKey;
        globalVerbY += verbSpacing;
      }
    }

    Map<String, List<String>> targetToVerbs = {};
    for (var entry in verbToTargetKey.entries) {
      if (entry.value.startsWith("sub_")) continue;
      targetToVerbs.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    for (var targetKey in targetToVerbs.keys) {
      List<String> verbIds = targetToVerbs[targetKey]!;
      double totalY = verbIds
          .where((v) => nodePositions.containsKey(v))
          .map((v) => nodePositions[v]!.dy)
          .fold(0.0, (a, b) => a + b);
      double avgY = totalY / verbIds.length;
      nodePositions[targetKey] = Offset(objectX, avgY);
    }
  }

  void _avoidCollision(String movedKey, Offset newPos) {
    const minDist = 70.0;
    nodePositions[movedKey] = newPos;
    for (var key in nodePositions.keys) {
      if (key == movedKey) continue;
      final other = nodePositions[key]!;
      final dist = (newPos - other).distance;
      if (dist < minDist && dist > 0) {
        final push = (other - newPos) / dist * (minDist - dist) * 0.5;
        nodePositions[key] = other + push;
      }
    }
  }

  void _onLassoPanStart(DragStartDetails details) {
    setState(() {
      _drawnPoints = [details.localPosition];
      _selectedNodeKeys.clear();
    });
  }

  void _onLassoPanUpdate(DragUpdateDetails details) {
    setState(() => _drawnPoints.add(details.localPosition));
  }

  void _onLassoPanEnd(DragEndDetails details) {
    setState(() {
      if (_drawnPoints.length > 2) {
        Path selectionPath = Path()..addPolygon(_drawnPoints, true);
        nodePositions.forEach((key, pos) {
          if (selectionPath.contains(pos)) _selectedNodeKeys.add(key);
        });
      }
      _drawnPoints.clear();
      _isLassoMode = false;
    });
  }

  // ===========================================================================
  // HÀM XỬ LÝ CẬP NHẬT STATUS STORY MỚI THÊM
  // ===========================================================================
  SprintStatus _mapStringToSprintStatus(String statusStr) {
    switch (statusStr.toUpperCase()) {
      case 'INPROGRESS':
        return SprintStatus.InProgress;
      case 'DONE':
        return SprintStatus.Done;
      case 'TODO':
      default:
        return SprintStatus.ToDo;
    }
  }

  Future<void> _updateStoryStatus(
    List<String> storyIds,
    String newStatus,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đang cập nhật ${storyIds.length} story thành $newStatus...',
        ),
      ),
    );

    bool allSuccess = true;

    // Chuyển đổi chuỗi String sang Enum trước khi gọi API
    SprintStatus enumStatus = _mapStringToSprintStatus(newStatus);

    for (String id in storyIds) {
      final success = await _userStoryService.updateUserStoryStatus(
        userStoryId: id,
        status: enumStatus, // Truyền Enum thay vì String
      );

      if (success) {
        setState(() {
          final index = _stories.indexWhere((s) => s.id == id);
          if (index != -1) {
            final old = _stories[index];
            _stories[index] = SprintSvoStory(
              id: old.id,
              rawText: old.rawText,
              subject: old.subject,
              verb: old.verb,
              object: old.object,
              status:
                  newStatus, // Trên UI (SprintSvoStory) bạn vẫn đang dùng String, nên giữ nguyên newStatus
            );
          }
        });
      } else {
        allSuccess = false;
      }
    }

    if (allSuccess) {
      setState(() {
        _selectedNodeKeys.clear();
        _calculateLayout(_stories);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cập nhật trạng thái thành công!'),
            backgroundColor: theme.doneColor,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi cập nhật một số story.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // HÀM XỬ LÝ COMPLETE SPRINT
  // ===========================================================================
  Future<void> _handleCompleteSprint() async {
    final success = await _sprintService.completeSprint(widget.sprintId);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sprint Completed Successfully!'),
            backgroundColor: theme.doneColor,
          ),
        );

        setState(() {
          _selectedNodeKeys.clear();
          _stories.removeWhere((story) => story.status.toUpperCase() == 'DONE');
          _calculateLayout(_stories);
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete sprint'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showActionMenu(BuildContext context, SprintSvoStory story) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.panelBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: theme.panelBorder),
      ),
      builder: (c) => Container(
        height: 280,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              story.rawText,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _statusChip(story.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${story.subject} → ${story.verb} → ${story.object}',
                    style: TextStyle(color: theme.textSecondary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Update Status:',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChangeBtn(
                  context,
                  story.id,
                  'ToDo',
                  Icons.list_alt,
                  theme.textSecondary,
                ),
                _buildStatusChangeBtn(
                  context,
                  story.id,
                  'InProgress',
                  Icons.autorenew,
                  theme.inProgressColor,
                ),
                _buildStatusChangeBtn(
                  context,
                  story.id,
                  'Done',
                  Icons.check_circle,
                  theme.doneColor,
                ),
              ],
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Complete Sprint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.doneColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _handleCompleteSprint();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChangeBtn(
    BuildContext context,
    String storyId,
    String statusName,
    IconData icon,
    Color color,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(statusName),
      style: ElevatedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () {
        Navigator.pop(context);
        _updateStoryStatus([storyId], statusName);
      },
    );
  }

  Widget _statusChip(String status) {
    Color color = status.toUpperCase() == 'DONE'
        ? theme.doneColor
        : (status.toUpperCase() == 'INPROGRESS'
              ? theme.inProgressColor
              : theme.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        title: Text(
          widget.sprintName.isNotEmpty ? widget.sprintName : "Sprint Graph",
          style: TextStyle(color: theme.textPrimary, fontSize: 16),
        ),
        backgroundColor: theme.panelBg,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.panelBorder, height: 1),
        ),
      ),
      floatingActionButton: _buildFab(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.subjectBorder))
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            )
          : Stack(
              children: [
                InteractiveViewer(
                  panEnabled: !_isLassoMode,
                  scaleEnabled: !_isLassoMode,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(2000),
                  minScale: 0.1,
                  maxScale: 4.0,
                  child: GestureDetector(
                    onPanStart: _isLassoMode ? _onLassoPanStart : null,
                    onPanUpdate: _isLassoMode ? _onLassoPanUpdate : null,
                    onPanEnd: _isLassoMode ? _onLassoPanEnd : null,
                    child: SizedBox(
                      width: 2500,
                      height: 2500,
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _spinController,
                            builder: (_, __) => CustomPaint(
                              size: const Size(2500, 2500),
                              painter: GraphLinesPainter(
                                nodePositions: nodePositions,
                                expandedSubjects: expandedSubjects,
                                mockData: _stories,
                                verbToTargetKey: verbToTargetKey,
                                subjects: _getUniqueSubjects(_stories),
                                hoveredKey: _hoveredNodeKey,
                                theme: theme,
                              ),
                            ),
                          ),
                          CustomPaint(
                            size: const Size(2500, 2500),
                            painter: ZoningPainter(
                              nodePositions: nodePositions,
                              zonedSubjects: zonedSubjects,
                              mockData: _stories,
                              isObjectASubject: (obj) =>
                                  _isObjectASubject(obj, _stories),
                              makeObjectKey: (name, status) =>
                                  _makeObjectKey(name, status),
                              theme: theme,
                            ),
                          ),
                          if (_isLassoMode && _drawnPoints.isNotEmpty)
                            CustomPaint(
                              size: const Size(2500, 2500),
                              painter: LassoPainter(
                                drawnPoints: _drawnPoints,
                                theme: theme,
                              ),
                            ),
                          ..._buildNodeWidgets(),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(top: 16, right: 16, child: _buildLegend()),
                if (_selectedNodeKeys.isNotEmpty)
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildStartSprintPanel()),
                  ),
              ],
            ),
    );
  }

  List<Widget> _buildNodeWidgets() {
    List<Widget> widgets = [];
    List<String> subjects = _getUniqueSubjects(_stories);

    for (var subName in subjects) {
      String key = "sub_$subName";
      if (nodePositions.containsKey(key)) {
        widgets.add(_buildNode(key, subName, NodeType.subject, null));
      }
    }

    for (var subName in expandedSubjects) {
      final subStories = _stories.where((e) => e.subject == subName).toList();
      for (var s in subStories) {
        String verbKey = "verb_${s.id}";
        if (nodePositions.containsKey(verbKey)) {
          widgets.add(_buildNode(verbKey, s.verb, NodeType.verb, s));
        }
      }
    }

    Set<String> renderedObjectKeys = {};
    for (var story in _stories) {
      if (_isObjectASubject(story.object, _stories)) continue;
      String objKey = _makeObjectKey(story.object, story.status);
      if (!renderedObjectKeys.contains(objKey) &&
          nodePositions.containsKey(objKey)) {
        renderedObjectKeys.add(objKey);
        widgets.add(_buildNode(objKey, story.object, NodeType.object, story));
      }
    }
    return widgets;
  }

  Widget _buildNode(
    String key,
    String text,
    NodeType type,
    SprintSvoStory? story,
  ) {
    Offset pos = nodePositions[key]!;
    double width = type == NodeType.verb ? 64 : 110;
    double height = type == NodeType.verb
        ? 64
        : (type == NodeType.subject ? 60 : 44);

    bool isHovered = _hoveredNodeKey == key;
    bool isSelected = _selectedNodeKeys.contains(key);
    int storyCount = type == NodeType.object
        ? _stories.where((s) => s.object == text).length
        : 0;

    return Positioned(
      left: pos.dx - width / 2,
      top: pos.dy - height / 2 - (type == NodeType.verb ? 12 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: _isLassoMode
                ? SystemMouseCursors.precise
                : SystemMouseCursors.move,
            onEnter: (_) => setState(() => _hoveredNodeKey = key),
            onExit: (_) => setState(() => _hoveredNodeKey = null),
            child: GestureDetector(
              onPanUpdate: (d) {
                if (!_isZoningMode && !_isLassoMode) {
                  setState(() => _avoidCollision(key, pos + d.delta));
                }
              },
              onTap: () {
                if (_isLassoMode) {
                  setState(() {
                    if (isSelected) {
                      _selectedNodeKeys.remove(key);
                    } else {
                      _selectedNodeKeys.add(key);
                    }
                  });
                } else if (type == NodeType.subject && !_isZoningMode) {
                  setState(() {
                    if (expandedSubjects.contains(text)) {
                      expandedSubjects.remove(text);
                    } else {
                      expandedSubjects.add(text);
                    }
                    _calculateLayout(_stories);
                  });
                } else if (type == NodeType.object && story != null) {
                  _showActionMenu(context, story);
                } else if (type == NodeType.verb && story != null) {
                  _showActionMenu(context, story);
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildNodeUI(
                    text,
                    type,
                    story,
                    width,
                    height,
                    isHovered,
                    isSelected,
                  ),
                  if (isHovered && type == NodeType.object)
                    Positioned(
                      left: width + 8,
                      top: 0,
                      child: _buildTooltip(text, storyCount),
                    ),
                ],
              ),
            ),
          ),
          if (type == NodeType.verb)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'expand',
                style: TextStyle(
                  color: theme.textSecondary.withOpacity(0.7),
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNodeUI(
    String text,
    NodeType type,
    SprintSvoStory? story,
    double w,
    double h,
    bool isHovered,
    bool isSelected,
  ) {
    switch (type) {
      case NodeType.subject:
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: w,
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.subjectBorder.withOpacity(0.3)
                : theme.subjectFill,
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(
              color: isSelected
                  ? theme.selectionBorder
                  : (isHovered
                        ? theme.subjectBorder
                        : theme.subjectBorder.withOpacity(0.7)),
              width: isSelected || isHovered ? 2.5 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.subjectBorder.withOpacity(
                  isSelected || isHovered ? 0.4 : 0.15,
                ),
                blurRadius: isSelected || isHovered ? 20 : 12,
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: text.length > 8 ? 12 : 14,
            ),
          ),
        );
      case NodeType.verb:
        return AnimatedBuilder(
          animation: _spinController,
          builder: (context, child) => CustomPaint(
            painter: _GlowCirclePainter(
              color: isSelected ? theme.selectionBorder : theme.verbBorder,
              glowRadius: (isSelected || isHovered) ? 0.8 : 0.4,
              animValue: _spinController.value,
            ),
            child: Container(
              width: w,
              height: h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.verbFill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.selectionBorder
                      : theme.verbBorder.withOpacity(isHovered ? 1.0 : 0.8),
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      case NodeType.object:
        Color borderColor = story?.status.toUpperCase() == 'DONE'
            ? theme.doneColor
            : (story?.status.toUpperCase() == 'INPROGRESS'
                  ? theme.inProgressColor
                  : theme.objectBorder);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: w,
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? borderColor.withOpacity(0.3) : theme.objectFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.selectionBorder
                  : (isHovered ? borderColor : borderColor.withOpacity(0.7)),
              width: isSelected || isHovered ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(
                  isSelected || isHovered ? 0.35 : 0.1,
                ),
                blurRadius: isSelected || isHovered ? 16 : 6,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildTooltip(String objectName, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.panelBg,
        border: Border.all(color: theme.panelBorder),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.tooltipShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            objectName,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Object entity -- reused in $count ${count == 1 ? 'story' : 'stories'}',
            style: TextStyle(color: theme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStartSprintPanel() {
    final selectedVerbKeys = _selectedNodeKeys
        .where((k) => k.startsWith('verb_'))
        .toList();
    final selectedStoryIds = selectedVerbKeys
        .map((k) => k.replaceFirst('verb_', ''))
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.verbBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.verbBorder.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${selectedStoryIds.length} Stories Selected',
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 20),

          PopupMenuButton<String>(
            tooltip: 'Update Status',
            onSelected: (newStatus) {
              if (selectedStoryIds.isNotEmpty) {
                _updateStoryStatus(selectedStoryIds, newStatus);
              }
            },
            offset: const Offset(0, -140),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: theme.panelBg,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.verbBorder,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Update Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'ToDo',
                child: Row(
                  children: [
                    Icon(Icons.list_alt, color: theme.textSecondary),
                    const SizedBox(width: 8),
                    Text('ToDo', style: TextStyle(color: theme.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'InProgress',
                child: Row(
                  children: [
                    Icon(Icons.autorenew, color: theme.inProgressColor),
                    const SizedBox(width: 8),
                    Text(
                      'InProgress',
                      style: TextStyle(color: theme.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Done',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: theme.doneColor),
                    const SizedBox(width: 8),
                    Text('Done', style: TextStyle(color: theme.textPrimary)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close, color: theme.textSecondary),
            onPressed: () => setState(() => _selectedNodeKeys.clear()),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.panelBg,
        border: Border.all(color: theme.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPRINT S-V-O',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          _legendItem(theme.subjectBorder, 'Actor (S)', isCircle: true),
          _legendItem(theme.objectBorder, 'Object (O)', isCircle: false),
          _legendItem(theme.verbBorder, 'Action (V)', isCircle: true),
        ],
      ),
    );
  }

  Widget _legendItem(
    Color color,
    String label, {
    bool isCircle = false,
    bool isDot = false,
  }) {
    Widget icon = isCircle
        ? Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          )
        : Container(
            width: 18,
            height: 12,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(3),
            ),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: theme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _fabButton(
          heroTag: "lasso",
          icon: Icons.gesture,
          active: _isLassoMode,
          onPressed: () => setState(() {
            _isLassoMode = !_isLassoMode;
            if (!_isLassoMode) _drawnPoints.clear();
          }),
        ),
        const SizedBox(height: 10),
        _fabButton(
          heroTag: "expand",
          icon: expandedSubjects.isEmpty
              ? Icons.unfold_more
              : Icons.unfold_less,
          onPressed: () => setState(() {
            if (expandedSubjects.length ==
                _getUniqueSubjects(_stories).length) {
              expandedSubjects.clear();
            } else {
              expandedSubjects.addAll(_getUniqueSubjects(_stories));
            }
            _calculateLayout(_stories);
          }),
        ),
        const SizedBox(height: 10),
        _fabButton(
          heroTag: "r",
          icon: Icons.refresh,
          onPressed: _loadSprintStories,
        ),
      ],
    );
  }

  Widget _fabButton({
    required String heroTag,
    required IconData icon,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      backgroundColor: active ? theme.verbBorder : theme.panelBg,
      elevation: 4,
      onPressed: onPressed,
      child: Icon(
        icon,
        color: active ? Colors.white : theme.textPrimary,
        size: 20,
      ),
    );
  }
}

// =============================================================================
// GRAPH PAINTERS
// =============================================================================
class GraphLinesPainter extends CustomPainter {
  final Map<String, Offset> nodePositions;
  final Set<String> expandedSubjects;
  final List<SprintSvoStory> mockData;
  final Map<String, String> verbToTargetKey;
  final List<String> subjects;
  final String? hoveredKey;
  final GraphTheme theme;

  GraphLinesPainter({
    required this.nodePositions,
    required this.expandedSubjects,
    required this.mockData,
    required this.verbToTargetKey,
    required this.subjects,
    this.hoveredKey,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var subName in subjects) {
      if (!expandedSubjects.contains(subName)) continue;
      String subKey = "sub_$subName";
      if (!nodePositions.containsKey(subKey)) continue;

      Offset subCenter = nodePositions[subKey]!;
      final stories = mockData.where((e) => e.subject == subName).toList();

      for (var s in stories) {
        String verbKey = "verb_${s.id}";
        if (!nodePositions.containsKey(verbKey)) continue;
        Offset verbCenter = nodePositions[verbKey]!;
        bool isHighlighted =
            hoveredKey == verbKey ||
            hoveredKey == subKey ||
            (verbToTargetKey[verbKey] != null &&
                hoveredKey == verbToTargetKey[verbKey]);
        final paint = Paint()
          ..color = isHighlighted
              ? theme.highlightLine.withOpacity(0.9)
              : theme.lineColor
          ..strokeWidth = isHighlighted ? 2.0 : 1.0
          ..style = PaintingStyle.stroke;

        final mid1 = Offset(
          (subCenter.dx + verbCenter.dx) / 2,
          (subCenter.dy + verbCenter.dy) / 2,
        );
        canvas.drawPath(
          Path()
            ..moveTo(subCenter.dx, subCenter.dy)
            ..quadraticBezierTo(
              mid1.dx,
              subCenter.dy,
              verbCenter.dx,
              verbCenter.dy,
            ),
          paint,
        );

        if (verbToTargetKey.containsKey(verbKey)) {
          String targetKey = verbToTargetKey[verbKey]!;
          if (nodePositions.containsKey(targetKey)) {
            Offset objCenter = nodePositions[targetKey]!;
            final mid2 = Offset(
              (verbCenter.dx + objCenter.dx) / 2,
              (verbCenter.dy + objCenter.dy) / 2,
            );
            canvas.drawPath(
              Path()
                ..moveTo(verbCenter.dx, verbCenter.dy)
                ..quadraticBezierTo(
                  mid2.dx,
                  verbCenter.dy,
                  objCenter.dx,
                  objCenter.dy,
                ),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GraphLinesPainter old) => true;
}

class ZoningPainter extends CustomPainter {
  final Map<String, Offset> nodePositions;
  final Set<String> zonedSubjects;
  final List<SprintSvoStory> mockData;
  final Function(String) isObjectASubject;
  final Function(String, String) makeObjectKey;
  final GraphTheme theme;

  ZoningPainter({
    required this.nodePositions,
    required this.zonedSubjects,
    required this.mockData,
    required this.isObjectASubject,
    required this.makeObjectKey,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (zonedSubjects.isEmpty) return;
    final paint = Paint()
      ..color = theme.verbBorder.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var subName in zonedSubjects) {
      final stories = mockData.where((e) => e.subject == subName).toList();
      for (var s in stories) {
        if (!isObjectASubject(s.object)) {
          String objKey = makeObjectKey(s.object, s.status);
          if (nodePositions.containsKey(objKey)) {
            _drawDashedCircle(canvas, nodePositions[objKey]!, 54, paint);
          }
        }
      }
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const double dashWidth = 8, dashSpace = 6;
    Path path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    for (ui.PathMetric metric in path.computeMetrics()) {
      double d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dashWidth), paint);
        d += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _GlowCirclePainter extends CustomPainter {
  final Color color;
  final double glowRadius;
  final double animValue;
  _GlowCirclePainter({
    required this.color,
    required this.glowRadius,
    required this.animValue,
  });
  @override
  void paint(Canvas canvas, Size size) {
    double pulse = 0.5 + 0.5 * sin(animValue * 2 * pi);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 + 4,
      Paint()
        ..color = color.withOpacity(0.15 + 0.1 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 4 * pulse),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowCirclePainter old) => true;
}

class LassoPainter extends CustomPainter {
  final List<Offset> drawnPoints;
  final GraphTheme theme;

  LassoPainter({required this.drawnPoints, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (drawnPoints.isEmpty) return;
    final path = Path()..moveTo(drawnPoints.first.dx, drawnPoints.first.dy);
    for (int i = 1; i < drawnPoints.length; i++) {
      path.lineTo(drawnPoints[i].dx, drawnPoints[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = theme.lassoColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant LassoPainter old) => true;
}
